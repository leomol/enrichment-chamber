% EnrichmentBox - Script to generate vectorized drawings for laser cutting
% an enrichment box with arbitrary maze designs.

% Notes for cutting:
% Ladder and bottle holder parts:
%   Some of the lines in the drawings are only intended for engraving with
%   the ultimate purpose of aiding in the bending of the part with heat.
% -Bottom front/back walls:
%   Only one of two sides require holes for the water bottles.
%   Discard bottle holes for the back wall.

% 2020-08-24. Leonardo Molina.
% 2023-09-13. Last Modified.

% Material.
mainWallThickness = 5.9;
mazeWallThickness = 3.0;
filmThickness = 0.75;

% General.
mainWallKerf = 0;
mazeWallKerf = 0;
toothWidth = 2 * mainWallThickness;
bendWidth = 3;

% Box approximate dimensions.
boxDy = 380;
bottomFloorDz = 175;
topFloorDz = 120;
leftCompartmentDx = 180;
rightCompartmentDx = boxDy;

% Holes.
accessWidth = 35;
accessEdgeOffset = 35;
accessHeight = accessWidth + 2 * mainWallThickness;
floorEdgeOffset = accessEdgeOffset;

% Bottle holder.
bottleWidth = 55 + 2;
bottleLength = 130;
bottleStrawDiameter = 8 + 0.5;
bottleStrawLift = 30;
bottleHolderClearance = 20;
bottleHolderProportion = 0.5;
bottleHolderToothCount = 15;

% Lower floor door.
doorwayRadius = 25;
doorwayLift = 40;
doorClearance = 5;
flapCutWidth = 2;
flapClearance = 5;
flexTall = 15;
flexCount = 5;
flexClearance = 10;

% Ladder.
% Distance from opposing wall to start of slope.
ladderStartOffset = 100;
% Extra length above access door.
ladderExtraLength = 60;
% Width clearance.
ladderStepsClearance = 10;
ladderStepApproximateHeight = 10;

% Ventilation holes.
ventilationRadius = 3;

% Margin to separate drawings.
margin = 3 * mainWallThickness;

% Fillet radius.
largeFillet = 2.00 * mainWallThickness;
smallFillet = 0.25 * mainWallThickness;

% Parts play.
movementPlay = 1;

% Mazes.
mazeWallToothCount = 13;
mazeFloorToothCount = 7;

mazes = getMazes();
thickParts = struct();
thinParts = struct();
filmParts = struct();

%% Adjust sizes to a proportion of material thickness.
boxDx = leftCompartmentDx + rightCompartmentDx + mainWallThickness;
boxNx = odd(boxDx / toothWidth);

boxNy = odd(boxDy / toothWidth);
topFloorNz = odd(topFloorDz / toothWidth);
bottomFloorNz = odd(bottomFloorDz / toothWidth);

boxDx = boxNx * toothWidth;
boxDy = boxNy * toothWidth;
topFloorDz = topFloorNz * toothWidth;
bottomFloorDz = bottomFloorNz * toothWidth;
boxDz = topFloorDz + bottomFloorDz;
rightCompartmentDx = boxDx - leftCompartmentDx - mainWallThickness;
mazeWallHeight = topFloorDz - 2 * mazeWallThickness - mainWallThickness;

mainWallTeeth = {toothWidth, mainWallThickness, +mainWallKerf};
mazeWallTeeth = {toothWidth, mazeWallThickness, +mazeWallKerf};
mainWallSlit = {toothWidth, mainWallThickness, [+mainWallKerf, 0]};
mazeWallSlit = {toothWidth, mazeWallThickness, [+mazeWallKerf, 0]};

%% Mazes.
mazeNames = fieldnames(mazes);
maze = mazes.(mazeNames{1});
vWallCount = size(maze.x, 2) + 1;
hWallCount = size(maze.x, 1);
vHallCount = vWallCount - 1;
hHallCount = hWallCount - 1;
maxWallCount = max(hWallCount, vWallCount);
minHallCount = min(vHallCount, hHallCount);
maxHallCount = max(vHallCount, hHallCount);
dHallCount = maxHallCount - minHallCount;
mazeWallWidth = (min(boxDx, boxDy) - maxWallCount * mazeWallThickness) / (maxWallCount - 1);
mazeDx = (vHallCount * mazeWallWidth + vWallCount * mazeWallThickness);
mazeDy = (hHallCount * mazeWallWidth + hWallCount * mazeWallThickness);
mazeRoofDx = mazeDx + 2 * mainWallThickness;
mazeRoofNx = oddDelta(mazeRoofDx / toothWidth, boxNx);
mazeRoofDx = mazeRoofNx * toothWidth;
mazeRoofDy = mazeDy + 2 * mainWallThickness;

mazeRoofDx2 = mazeRoofDx - movementPlay;
mazeRoofDy2 = mazeRoofDy - movementPlay;

mazeOffset = [mazeRoofDx2 - mazeDx, mazeRoofDy2 - mazeDy] / 2;

start = [0, 0];
mazeGuides = struct();
mazeWalls = struct();
nMazes = numel(mazeNames);

figure(2);
for m = 1:nMazes
    mazeName = mazeNames{m};
    maze = mazes.(mazeName);
    % Thin.
    [guides, walls] = drawMaze(mazeOffset, maze.x, maze.y, mazeWallWidth, mazeWallHeight, mazeWallThickness, mainWallThickness, mazeWallToothCount, mazeFloorToothCount, mazeWallKerf);

    % Boundaries. Thick.
    guides.move(start(1), start(2));
    guides.rectangle(mazeRoofDx2, mazeRoofDy2, smallFillet, +mainWallKerf);

    % Ventilation. Thick.
    guides.move(mazeOffset(1), mazeOffset(2));
    guides.shift(-dHallCount * mazeWallWidth / 2 + 3 * mazeWallWidth / 2, mazeWallWidth / 2 + mazeWallThickness);
    xs = (0:maxHallCount - 3) * (mazeWallWidth + mazeWallThickness);
    xs = repmat(xs, hHallCount, 1);
    ys = (cumsum(ones(size(xs)), 1) - 1) * (mazeWallWidth + mazeWallThickness);
    guides.circle(xs, ys, ventilationRadius, mainWallKerf);

    % Plot and style.
    subplot(1, nMazes, m);
    cla();
    hold('all');
    plot(guides.x, guides.y);
    plot(walls.x, walls.y);
    axis('equal');
    set(gca(), 'XTick', [], 'YTick', []);
    box('on');

    mazeGuides.(mazeName) = guides;
    mazeWalls.(mazeName) = walls;
end

%% Initialize figure.
figure(1);
cla();
hold('all');

%% Bottom - Front/back walls.
start = [0, 0];
sketch = CAD(start(1), start(2));
sketch.wave('E0', boxNx, mainWallTeeth{:});
sketch.tooth('S|1001|', bottomFloorNz, mainWallTeeth{:});
sketch.tooth('W|0110|', boxNx, mainWallTeeth{:});
sketch.tooth('N|1001|', bottomFloorNz, mainWallTeeth{:});
sketch.close();
sketch.move(start(1) + leftCompartmentDx, start(2) - bottomFloorDz);
sketch.slit('n0', bottomFloorNz, mainWallSlit{:});
sketch.move(start(1), start(2) - 3 / 2 * toothWidth);
xs = [2:leftCompartmentDx / toothWidth - 1, leftCompartmentDx / toothWidth + 2:(leftCompartmentDx + rightCompartmentDx) / toothWidth - 1] * toothWidth;
ys = zeros(size(xs));
sketch.circle(xs, ys, ventilationRadius, mainWallKerf);

% Bottle holder holes.
holderWidth = bottleWidth + 2 * bottleHolderClearance;
dim1 = bottleHolderProportion * bottleLength * sqrt(2) / 2;
dim2 = holderWidth;
dim3 = dim1;
dim4 = (bottleWidth + 2 * bottleHolderClearance) * sqrt(2) / 2 + dim1;
holderLength = dim1 + dim2 + dim3 + dim4;
xCenter = start(1) + boxDx - rightCompartmentDx / 2;
bottomSlitStart = [xCenter - 1.5 * bottleWidth - 2 * bottleHolderClearance, start(2) - bottomFloorDz + bottleStrawLift];
strawCenter = [xCenter, bottomSlitStart(2) + 2 * mainWallThickness + bottleStrawDiameter / 2];
sketch.move(strawCenter(1), strawCenter(2));
sketch.circle([-(bottleWidth + bottleHolderClearance), 0, bottleWidth + bottleHolderClearance], [0, 0, 0], bottleStrawDiameter / 2, mainWallKerf);
k = 0.20;
plot(sketch.x, sketch.y);
thickParts.bottomFront = sketch;

%% Bottom - Side walls.
start = [boxDx + margin, 0];
sketch = CAD(start(1), start(2));
sketch.line('E+-', toothWidth, mainWallKerf);
sketch.wave('E0', boxNy - 2, mainWallTeeth{:});
sketch.line('E+-', toothWidth, mainWallKerf);
sketch.tooth('S|0110|', bottomFloorNz, mainWallTeeth{:});
sketch.tooth('W|0110|', boxNy, mainWallTeeth{:});
sketch.tooth('N|0110|', bottomFloorNz, mainWallTeeth{:});
sketch.close();
sketch.cut();

sketch.move(start(1), start(2) - 3 / 2 * toothWidth);
xs = (2:boxNy - 2) * toothWidth;
ys = zeros(size(xs));
sketch.circle(xs, ys, ventilationRadius, mainWallKerf);
plot(sketch.x, sketch.y, '-');
thickParts.bottomSide = sketch;

%% Bottom - Floor holder.
start = [0, -bottomFloorDz - margin];
sketch = CAD(start(1), start(2));
sketch.tooth('E{1111}', boxNx, mainWallTeeth{:});
sketch.tooth('S{1111}', boxNy, mainWallTeeth{:});
sketch.tooth('W{1111}', boxNx, mainWallTeeth{:});
sketch.tooth('N{1111}', boxNy, mainWallTeeth{:});
sketch.close();
sketch.shift(leftCompartmentDx, 0);
sketch.slit('S0', boxNy, mainWallSlit{:});
sketch.move(start(1) + floorEdgeOffset, start(2) - floorEdgeOffset);
sketch.rectangle(leftCompartmentDx - 2 * floorEdgeOffset, -(boxDy - 2 * floorEdgeOffset), smallFillet, -mainWallKerf);
sketch.move(start(1) + leftCompartmentDx + mainWallThickness + floorEdgeOffset, start(2) - floorEdgeOffset);
sketch.rectangle(rightCompartmentDx - 2 * floorEdgeOffset, -(boxDy - 2 * floorEdgeOffset), smallFillet, -mainWallKerf);
plot(sketch.x, sketch.y, '-');
thickParts.bottomFloorHolder = sketch;

%% Bottom - Floors. Thin.
start = [0, -bottomFloorDz - boxDy - 2 * margin];
sketch = CAD(start(1), start(2));
sketch.shift(movementPlay / 2, 0);
sketch.rectangle(leftCompartmentDx - movementPlay, -(boxDy - movementPlay), smallFillet, +mazeWallKerf);
sketch.shift(leftCompartmentDx + mainWallThickness + movementPlay, 0);
sketch.rectangle(rightCompartmentDx - movementPlay, -(boxDy - movementPlay), smallFillet, +mazeWallKerf);
plot(sketch.x, sketch.y);
thinParts.bottomFloor = sketch;
plot(sketch.x, sketch.y, '-');

%% Bottom - Inner wall and doorways.
start = [boxDx + margin, -bottomFloorDz - margin];

flapHeight = mainWallThickness;
flapWidth = 2 * doorwayRadius;
doorheight = doorwayRadius + flexTall + flapHeight + 3 * flapClearance;
doorWidth = flapWidth + 2 * doorClearance;
separation = boxDy / 6;
center = start(1) + boxDy / 2;
vertical = start(2) - bottomFloorDz + doorwayLift + doorwayRadius;
doorCenters = [center - separation, center + separation];
cutOffset = [0, doorheight - flapClearance];

sketch = CAD(start(1), start(2));
sketch.line('E', boxDy, mainWallKerf);
sketch.tooth('S|0110|', bottomFloorNz, mainWallTeeth{:});
sketch.tooth('W|0110|', boxNy, mainWallTeeth{:});
sketch.tooth('N|0110|', bottomFloorNz, mainWallTeeth{:});
sketch.close();
sketch.cut();

sketch.move(center - separation, vertical);
sketch.circle(doorwayRadius, 360 * 2, -mainWallKerf);
sketch.shift(-flapWidth / 2, cutOffset(2) - filmThickness / 2);
sketch.rectangle(flapWidth, filmThickness, [0, -mainWallKerf]);
sketch.move(center + separation, vertical);
sketch.circle(doorwayRadius, 360 * 2, -mainWallKerf);
sketch.shift(-flapWidth / 2, cutOffset(2) - filmThickness / 2);
sketch.rectangle(flapWidth, filmThickness, [0, -mainWallKerf]);

plot(sketch.x, sketch.y);
thickParts.bottomInner = sketch;

%% Bottom - Door.
start = [doorCenters(1), -2 * bottomFloorDz - doorheight - 2 * margin];
sketch = CAD(start(1), start(2));

% Flap.
sketch.shift(flapWidth / 2 - flapCutWidth, cutOffset(2));
sketch.line('E--', flapCutWidth, -mazeWallKerf);
sketch.line('S+-', flapHeight, -mazeWallKerf);
sketch.line('W+-', flapWidth, -mazeWallKerf);
sketch.line('N+-', flapHeight, -mazeWallKerf);
sketch.line('E++', flapCutWidth, -mazeWallKerf);
sketch.cut();

% Door.
sketch.move(start(1), start(2) + cutOffset(2));
sketch.shift(0, flapClearance);
sketch.line('E+-', doorWidth / 2 - smallFillet, mazeWallKerf);
sketch.arc('SE', smallFillet, mazeWallKerf);
sketch.line('S+-', doorheight - smallFillet, mazeWallKerf);
sketch.arc('W', 2 * doorwayRadius + 2 * doorClearance, pi, mazeWallKerf);
sketch.line('N+-', doorheight - smallFillet, mazeWallKerf);
sketch.arc('NE', smallFillet, mazeWallKerf);
sketch.line('E++', doorWidth / 2 - smallFillet, mazeWallKerf);

% Flex.
sketch.move(start(1) - doorWidth / 2, start(2) + doorwayRadius + flapClearance);
sketch.flex('E0', doorWidth, flexTall, flexCount, flexClearance);

plot(sketch.x, sketch.y);
filmParts.door = sketch;

%% Top - Front/back walls.
start = [0, margin];
sideRoofN = (boxNx - mazeRoofNx) / 2;
sketch = CAD(start(1), start(2));
sketch.tooth('N[1111}', topFloorNz, mainWallTeeth{:});
sketch.tooth('E[1101|', sideRoofN, mainWallTeeth{:});
sketch.line('E+-', mazeRoofDx, mainWallKerf);
sketch.tooth('E|1011]', sideRoofN, mainWallTeeth{:});
sketch.tooth('S{1111]', topFloorNz, mainWallTeeth{:});
sketch.wave('W1', boxNx, mainWallTeeth{:});
sketch.close();
sketch.cut();
sketch.move(start(1), start(2) + mainWallThickness);
% Mixed design.
sketch.slit('E0', boxNx, toothWidth, mazeWallThickness, [+mainWallKerf, 0]);
plot(sketch.x, sketch.y, '-');
thickParts.topFront = sketch;

%% Top - Roof part.
start = [boxDx - (boxDx - mazeRoofDx) / 2, topFloorDz + 2 * margin];
sketch = CAD(start(1), start(2));
sketch.line('N', boxDy, mainWallKerf);
sketch.tooth('E|0110|', sideRoofN, mainWallTeeth{:});
sketch.tooth('S|1001|', boxNy, mainWallTeeth{:});
sketch.tooth('W|0110|', sideRoofN, mainWallTeeth{:});
plot(sketch.x, sketch.y, '-');
thickParts.topRoof = sketch;

%% Top - Side walls.
start = [boxDx + margin, margin];
sketch = CAD(start(1), start(2));
sketch.tooth('N{0010|', topFloorNz, mainWallTeeth{:});
sketch.tooth('E|0110|', boxNy, mainWallTeeth{:});
sketch.tooth('S|0100{', topFloorNz, mainWallTeeth{:});
sketch.line('W+-', toothWidth, mainWallKerf);
sketch.shift(0, +mainWallThickness);
sketch.wave('W1', boxNy - 2, mainWallTeeth{:});
sketch.line('W+-', toothWidth, mainWallKerf);
sketch.close();
sketch.move(start(1), start(2) + mainWallThickness);
% Mixed design.
sketch.slit('E0', boxNy, toothWidth, mazeWallThickness, [+mainWallKerf, 0]);
plot(sketch.x, sketch.y, '-');
thickParts.topSide = sketch;

%% Top - Floor holder. Thin.
start = [-margin, margin];
sketch = CAD(start(1), start(2));
sketch.tooth('W|0110|', boxNx, toothWidth, mainWallThickness, mazeWallKerf);
sketch.tooth('N|0110|', boxNy, toothWidth, mainWallThickness, mazeWallKerf);
sketch.tooth('E|0110|', boxNx, toothWidth, mainWallThickness, mazeWallKerf);
sketch.tooth('S|0110|', boxNy, toothWidth, mainWallThickness, mazeWallKerf);
sketch.close();
sketch.move(start(1) - boxDx + accessEdgeOffset, start(2) + accessEdgeOffset);
sketch.rectangle(boxDx - 2 * accessEdgeOffset, (boxDy - 2 * accessEdgeOffset), smallFillet, -mazeWallKerf);
plot(sketch.x, sketch.y, '-');
thinParts.topFloorHolder = sketch;

%% Top - Floor. Thin.
start = [-margin, 0];
sketch = CAD(start(1), start(2));
sketch.rectangle(-(boxDx - movementPlay) / 2, -(boxDy - movementPlay), smallFillet, +mazeWallKerf);
sketch.move(start(1) - accessEdgeOffset, start(2) - accessEdgeOffset);
width = accessWidth + movementPlay;
height = accessHeight + movementPlay;
sketch.rectangle(-width, -height, smallFillet, -mazeWallKerf);
plot(sketch.x, sketch.y);
thinParts.topFloor = sketch;

%% Ladders.
bendCorrection = 2 * pi * bendWidth / 4;
climbLength = sqrt(bottomFloorDz ^ 2 + (boxDy - ladderStartOffset - accessEdgeOffset) ^ 2);
ladderLength = ladderStartOffset + bendCorrection + climbLength + bendCorrection + accessEdgeOffset;
stepCount = odd(climbLength / ladderStepApproximateHeight);
holeCount = (stepCount - 1) / 2;
stepHeight = climbLength / stepCount;
start = [-margin - accessEdgeOffset - accessWidth, -boxDy - margin - ladderLength];
sketch = CAD(start(1), start(2));
sketch.rectangle(accessWidth + accessEdgeOffset, ladderLength, smallFillet, +mainWallKerf);
sketch.shift(0, ladderStartOffset + bendCorrection / 2 - bendWidth / 2);
sketch.rectangle(accessWidth + accessEdgeOffset, bendWidth, 0);
sketch.shift(0, bendCorrection / 2 + bendWidth / 2);
stepMargin = 2;
sketch.shift(ladderStepsClearance, stepMargin * stepHeight);
sketch.shift(0, stepHeight);
for i = 1:holeCount - stepMargin
    sketch.rectangle(accessWidth, stepHeight, smallFillet, mainWallKerf);
    sketch.shift(0, 2 * stepHeight);
end
sketch.shift(-ladderStepsClearance, stepMargin * stepHeight);
sketch.shift(0, bendCorrection / 2 - bendWidth / 2);
sketch.rectangle(accessWidth + accessEdgeOffset, bendWidth, 0);
plot(sketch.x, sketch.y);
thickParts.ladder = sketch;

%% Style plots.
axis('equal');
set(gca(), 'XTick', [], 'YTick', []);
box('on');

%% Export. !!
% Create output folders.
makedir('CAD', 'CAD/thick', 'CAD/thin', 'CAD/film');

fnames = fieldnames(filmParts);
for f = 1:numel(fnames)
    fname = fnames{f};
    filename = fullfile('CAD/film', sprintf('film-%s.svg', fname));
    filmParts.(fname).export(filename);
end
fnames = fieldnames(thickParts);
for f = 1:numel(fnames)
    fname = fnames{f};
    filename = fullfile('CAD/thick', sprintf('thick-%s.svg', fname));
    thickParts.(fname).export(filename);
end
fnames = fieldnames(thinParts);
for f = 1:numel(fnames)
    fname = fnames{f};
    filename = fullfile('CAD/thin', sprintf('thin-%s.svg', fname));
    thinParts.(fname).export(filename);
end
fnames = fieldnames(mazeGuides);
for f = 1:numel(fnames)
    fname = fnames{f};
    filename = fullfile('CAD/thick', sprintf('maze-guides-%s.svg', fname));
    mazeGuides.(fname).export(filename);
    filename = fullfile('CAD/thin', sprintf('maze-walls-%s.svg', fname));
    mazeWalls.(fname).export(filename);
end

%% Function helpers.
function makedir(varargin)
    for i = 1:nargin
        folder = varargin{i};
        if ~exist(folder, 'dir')
            mkdir(folder)
        end
    end
end

% Closest odd integer to ceil(k)
function k = odd(k)
    k = ceil(k) + (mod(ceil(k), 2) == 0);
end

% Get a number such that (odd(k) - odd(reference)) / 2 is odd.
function k = oddDelta(k, reference)
    k = odd(k);
    reference = odd(reference);
    if mod((k - reference) / 2, 2) == 0
        k = k + 2;
    end
end

% getMazes - Generate arbitrary maze designs programatically.
% 2020-08-24. Leonardo Molina.
% 2023-08-24. Last Modified.
function mazes = getMazes()
    mazes = struct();
    mazes.a1.x = [
        1 1 1 1 1
        0 1 1 1 0
        0 0 1 0 1
        0 0 1 1 0
        1 1 1 0 1
        0 0 1 0 0
        0 0 0 1 0
        1 1 1 1 1
        ];
    mazes.a1.y = [
        1 0 0 0 0 1
        1 1 0 1 0 1
        1 1 0 0 0 1
        0 1 0 0 1 0
        1 0 0 1 0 1
        1 1 1 0 1 0
        0 1 0 0 1 1
        ];

    mazes.c1.x = [
        1 1 1 1 1
        0 0 0 0 0
        0 0 0 0 0
        1 0 0 1 0
        1 1 0 0 1
        0 0 0 1 1
        0 0 1 1 0
        1 1 1 1 1
        ];
    mazes.c1.y = [
        1 0 0 1 0 1
        1 1 1 1 1 1
        1 1 1 0 1 1
        0 0 1 0 1 0
        1 0 1 1 0 0
        1 1 1 0 0 1
        0 1 0 0 0 1
        ];

    mazes.e1.x = [
        1 1 1 1 1
        0 0 1 1 0
        0 1 0 0 0
        0 0 0 0 0
        1 0 1 0 1
        0 1 0 1 1
        0 0 1 1 1
        1 1 1 1 1
        ];
    mazes.e1.y = [
        0 1 0 0 0 1
        1 1 0 1 1 1
        1 1 0 1 1 1
        1 0 1 1 0 1
        1 0 0 1 0 0
        1 1 0 0 0 1
        0 1 0 0 0 0
        ];

    mazes.b1.x = [
        1 1 1 1 1
        0 0 1 1 0
        0 1 1 0 0
        0 0 1 0 0
        0 0 0 1 1
        0 0 1 1 0
        0 0 0 1 0
        1 1 1 1 1
        ];
    mazes.b1.y = [
        1 0 1 0 0 1
        1 1 0 0 1 0
        1 0 0 1 1 1
        1 1 1 0 0 1
        0 1 1 0 0 0
        1 1 0 0 1 1
        0 1 1 0 0 1
        ];

    mazes.d1.x = [
        1 1 1 1 1
        0 0 1 1 0
        0 0 1 0 0
        0 1 1 0 0
        0 1 1 0 0
        0 0 1 0 1
        0 0 0 1 0
        1 1 1 1 1
        ];
    mazes.d1.y = [
        0 1 0 0 0 1
        1 1 0 0 1 1
        1 1 0 1 1 0
        1 0 0 0 1 1
        1 1 0 0 1 1
        0 1 1 0 1 0
        1 0 1 0 0 1
        ];

    mazes.f1.x = [
        1 1 1 1 1
        0 0 1 1 0
        0 1 1 0 0
        0 1 1 0 0
        0 0 0 0 0
        0 0 0 1 1
        0 0 0 1 0
        1 1 1 1 1
        ];
    mazes.f1.y = [
        1 0 1 0 0 1
        1 1 0 0 1 1
        0 1 0 0 1 0
        1 1 1 0 1 1
        0 1 0 1 0 1
        1 1 1 0 0 0
        1 0 1 1 0 1
        ];
end
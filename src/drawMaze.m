% drawMaze - Generate arbitrary maze designs for the Enrichment Box.

% 2020-08-24. Leonardo Molina.
% 2023-08-24. Last Modified.
function [guides, walls] = drawMaze(start, horizontalWalls, verticalWalls, wallWidth, wallHeight, wallThickness, floorThickness, wallToothCount, floorToothCount, kerf)
    
    % Teeth:
    %   Tight fit among parts.
    %   Compensate kerf equally in width and height.
    % Slits:
    %   Compensate for kerf on the width but not on the height so that teeth
    %   fit tighly but allows minimal play on the thickness.
    % Slit kerf is larger than teeth kerf.
    
    wallToothWidth = wallHeight / wallToothCount;
    floorToothWidth = wallWidth / floorToothCount;
    floorSlitVars = {floorToothWidth, wallThickness, [kerf, 0]};
    floorToothVars = {floorToothWidth, floorThickness, kerf};
    
    % Guides.
    guides = CAD(start(1), start(2));
    
    % Horizontal holes.
    guides.move(start(1), start(2));
    [nr, nc] = size(horizontalWalls);
    for i = 1:nr
        for j = 1:nc
            guides.shift(wallThickness, 0);
            if horizontalWalls(nr - i + 1, j)
                guides.slit('E1', floorToothCount, floorSlitVars{:});
            end
            guides.shift(wallWidth, 0);
        end
        guides.shift(-nc * (wallWidth + wallThickness), wallWidth + wallThickness);
    end
    
    % Vertical holes.
    guides.move(start(1), start(2));
    [nr, nc] = size(verticalWalls);
    for j = 1:nc
        for i = 1:nr
            guides.shift(0, wallThickness);
            if verticalWalls(nr - i + 1, j)
                guides.slit('n1', floorToothCount, floorSlitVars{:});
            end
            guides.shift(0, wallWidth);
        end
        guides.shift(wallWidth + wallThickness, -nr * (wallWidth + wallThickness));
    end
    
    % Find walls and configurations.
    hWalls = parseWalls(horizontalWalls, verticalWalls, false, false);
    vWalls = parseWalls(horizontalWalls, verticalWalls, true, true);
    vWalls = cellfun(@(x) -x, vWalls, 'UniformOutput', false);
    parsedWalls = [hWalls, vWalls];
    nWalls = numel(parsedWalls);
    
    walls = CAD(start(1), start(2));
    for w = 1:nWalls
        walls.cut();
        walls.move(start(1) + wallThickness, start(2) - wallWidth - (w - 1) * (wallHeight + 2 * floorThickness));
        parsedWall = parsedWalls{w};
        nParts = numel(parsedWall) - 1;
        nInternal = max(0, nParts - 2);
        % Floor teeth.
        if nParts == 1
            walls.tooth('E|1001|', floorToothCount, floorToothVars{:});
        else
            walls.tooth('E|1001|', floorToothCount, floorToothVars{:});
            for i = 1:nInternal
                walls.shift(wallThickness, 0);
                walls.tooth('E|1001|', floorToothCount, floorToothVars{:});
            end
            walls.shift(wallThickness, 0);
            walls.tooth('E|1001|', floorToothCount, floorToothVars{:});
        end
        % Wall rising edge.
        %   Primary walls:
        %     T | B | T&B    ==> 010101010101
        %   Secondary walls:
        %     T | B | T&B    ==> 101010101010
        %     L intersection ==> 100010001000
        %     R intersection ==> 001000100010
        if parsedWall(end) == 0
            % Line.
            walls.line('S', wallHeight, kerf);
        else
            ends = [true, true];
            protrude = true;
            if parsedWall(end) > 0
                levels = getTeeth(3, wallToothCount);
            else
                levels = getTeeth(parsedWall(end), wallToothCount);
            end
            widths = wallToothWidth * ones(size(levels));
            [xk, yk] = CAD.Tooth(widths, levels, wallThickness, ends, kerf, protrude);
            [x0, y0] = CAD.Tooth(widths, levels, wallThickness, ends, 0, protrude);
            [xk, yk] = rotate(3 * pi / 2, xk, yk);
            [x0, y0] = rotate(3 * pi / 2, x0, y0);
            walls.append(xk, yk, x0, y0);
            walls.move();
        end
        % Wall bottom.
        width = nParts * wallWidth + (nParts - 1) * wallThickness;
        walls.line('W', width, kerf);
        % Wall rising edge.
        if parsedWall(1) == 0
            % Line.
            walls.line('N', wallHeight, kerf);
        else
            ends = [true, true];
            protrude = true;
            if parsedWall(1) > 0
                levels = getTeeth(3, wallToothCount);
            else
                levels = getTeeth(parsedWall(1), wallToothCount);
            end
            levels = levels(end:-1:1);
            widths = wallToothWidth * ones(size(levels));
            [xk, yk] = CAD.Tooth(widths, levels, wallThickness, ends, kerf, protrude);
            [x0, y0] = CAD.Tooth(widths, levels, wallThickness, ends, 0, protrude);
            [xk, yk] = rotate(pi / 2, xk, yk);
            [x0, y0] = rotate(pi / 2, x0, y0);
            walls.append(xk, yk, x0, y0);
            walls.move();
        end
        % Slit.
        for i = 2:numel(parsedWall) - 1
            walls.shift(wallWidth, 0);
            if parsedWall(i) ~= 0
                levels = getSlit(parsedWall(i), wallToothCount);
                widths = wallToothWidth * ones(size(levels));
                [xk, yk] = CAD.Slit(widths, levels, wallThickness, [0, kerf]);
                [x0, y0] = CAD.Slit(widths, levels, wallThickness, [0, 0]);
                [xk, yk] = rotate(3 * pi / 2, xk, yk);
                [x0, y0] = rotate(3 * pi / 2, x0, y0);
                walls.append(xk, yk, x0, y0);
            end
            walls.shift(wallThickness, 0);
        end
    end
    
end


function walls = parseWalls(x, y, flip, interruptible)
    % Each cell encodes an uninterrupted wall with nodes with:
    %   0 no intersection.
    %   1 bottom intersection.
    %   2 top intersection.
    %   3 bottom and top intersections.
    %   4 thru-wall on left.
    %   5 thru-wall on right.
    if flip
        [x, y] = deal(y', x');
    end
    
    [nr, nc] = size(x);
    wall = [];
    walls = cell(1, 0);
    encode = @(a, b) bitor(bitshift(int8(a), 1), int8(b));
    for i = 1:nr
        for j = 1:nc
            hasPrevious = j - 1 >= 1 && x(i, j - 1);
            if x(i, j)
                % Orthogonal intersections.
                LB = i < nr && y(i, j) == 1;
                LT = i > 1 && y(i - 1, j) == 1;
                RB = i < nr && y(i, j + 1) == 1;
                RT = i > 1 && y(i - 1, j + 1) == 1;
                % Passing-through.
                if interruptible && hasPrevious && LB && LT
                    walls = cat(2, walls, [wall, 5]);
                    wall = 4;
                else
                    wall = cat(2, wall, encode(LT, LB));
                end
                
                if j == nc
                    walls = cat(2, walls, [wall, encode(RT, RB)]);
                    wall = [];
                end
                
            elseif hasPrevious
                walls = cat(2, walls, [wall, encode(RT, RB)]);
                wall = [];
            end
        end
    end
end

function levels = getTeeth(type, count)
    levels = zeros(1, count);
    switch type
        case {+1, +2, +3}
            % Horizontal teeth no matter the intersection.
            % Full odd teeth.
            % |010101010101 .. |
            levels(2:2:end) = 1;
        case {-1, -2}
            % Vertical teeth to horizontal teeth.
            % |101010101010 .. |
            levels(1:2:end) = 1;
        case -3
            % Single vertical teeth to horizontal slit.
            % |00101010 .. 0|
            levels(3:2:end) = 1;
            levels(end) = 0;
        case -4
            % First vertical teeth to horizontal slit.
            % |000010001000 .. 0|
            levels(5:4:end) = 1;
            levels(end) = 0;
        case -5
            % Second vertical teeth to horitontal slit.
            % |00100010001000 .. 0|
            levels(3:4:end) = 1;
            levels(end) = 0;
    end
end

function levels = getSlit(type, count)
    levels = zeros(1, count);
    switch type
        case {+1, +2, +3}
            % Horizontal slit receives top, bottom, or top & bottom odd teeth.
            % |0010101010 .. 0|
            levels(3:2:end) = 1;
            levels(end) = 0;
        case {-1, -2}
            % Vertical slit receives odd teeth.
            % 010101010101
            levels(2:2:end) = 1;
    end
end

function [x2, y2] = rotate(angle, x, y)
    cosR = cos(angle);
    sinR = sin(angle);
    x2 = x * cosR - y * sinR;
    y2 = y * cosR + x * sinR;
end
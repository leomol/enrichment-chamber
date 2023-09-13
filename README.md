# Enrichment chamber
CAD files and assembly instructions for an enrichment chamber as in the picture below.<br>
All the floors, the ladders, and the maze are removable.<br>
Code to create the cad files programmatically (including option to adjust the kerf) is provided in `main.m`.<br>
Mazes can be designed with simple text instructions (see 6 examples at the end of `main.m`).<br>

![](media/apparatus-picture.png)

See related resources:
- [CAD library][cad-library]

## Components
- [6mm clear acrylic sheets](https://www.polymershapes.com/product/acrylic/)
- [3mm black acrylic sheets](https://www.polymershapes.com/product/acrylic/)

## Assembly instructions
- Laser cut the acrylic sheets using the [provided CAD drawings](CAD). Remove protective film.
- Assemble all acrylic parts (except removable parts) using painter's tape and apply acrylic cement or 2-part epoxy.
- Remove painter's tape after drying.

![](media/apparatus-diagram.png)

## Recreating CAD files programmatically
### Prerequisites
- [MATLAB][MATLAB] (last tested with R2023a)

### Installation
- Install [MATLAB][MATLAB]
- Download and extract the [CAD library][cad-library] to the `Documents/MATLAB` folder (see [the library's installation instructions][cad-library]).
- Download and extract the [project scripts][project] to `Documents/MATLAB` folder.
- Edit sizes and maze designs and run `main.m`.

## Changelog
See [Changelog](CHANGELOG.md)

## License
© 2021 [Leonardo Molina][Leonardo Molina]

### License for the aparatus and CAD files
[Creative Commons BY-NC-SA 4.0 License][cad-license]

### License for the source code
[GNU GPLv3 License][code-license]

[cad-library]: https://github.com/leomol/cad
[project]: https://github.com/leomol/enrichment-chamber
[code-license]: src/LICENSE.md
[cad-license]: CAD/LICENSE.md
[Leonardo Molina]: https://github.com/leomol
[MATLAB]: https://www.mathworks.com/downloads/
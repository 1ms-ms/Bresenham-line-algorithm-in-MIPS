# Bresenham's line algorithm in MIPS assembly
## Prerequisites
The project focuses on drawing a straight line between 2 points , while using a Bresenham's algorithm: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm.<br /><br />
The code shown in bresenham.asm has been compiled using MARS MIPS simulator, which can be downloaded here: https://courses.missouristate.edu/kenvollmar/mars/download.htm. <br /><br />
Either black32x32.bmp or white32x32.bmp should be used as a background for the drawing. The output is saved to result.bmp *in the same folder* as the MARS MIPS simulator. Both read and save errors return adequate message.

## General info
Besides the input mentioned in the previous section, there are 5 different values that need to be supplied: color of the pixel (either 0 or 1), as well as, coordinates of each point P1(cx,cy) and P2(x,y).
The assignement of these variables and those, which are used later has been commented in the code. As the code runs on MARS MIPS simulator which provides a clear GUI, there are no additional informations how to compile this code, besides the knowledge of MARS MIPS simulator, which can be found in a documentation.


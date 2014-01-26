# Tkar protocol

This document describes the syntax and semantics of the text commands sent over the two-way communication stream (pipe, tcp socket, unix socket) to the tkar process. (The binary protocol is not documented here.)

See also the command-line options for tkar by running it with the -h option:

      tkar -h

## Syntax

Commands are case sensitive and separated by newlines, and arguments are separated (from commands and from each other) by spaces:

      command1 arg0 arg1 arg2
      command2 arg0 arg1 arg2

Use a backslash ("\") character at the end of a line to continue to the next line:

      command1 arg0 \
        arg1 arg2

Blank lines are ignored. Spaces before text on a line are ignored. Extra spaces between arguments is not significant.

Lines which are blank up to a # character are ignored (the text after the # is a comment):

      command1 arg0 arg1 arg2
      #command2 arg0 arg1 arg2 this line is not executed

However, # characters are significant after non-whitespace characters:

      command1 arg0 arg1 #F0A020

The last argument is a typical color parameter.

## Process control

*`wait t`*

Tells tkar to sleep for up to t seconds before processessing the next command. The value may be floating point.

Wait is a way to keep the frame rate constant. A single timer with memory is used for all waits, so that if wait is called repeatedly, sleep time is reduced by the amount of time used for processing since the last wait. If processing time is less than wait time, the next processing cycle will begin exactly t seconds after the previous one (subject to OS process scheduling limitations).

*`done`*

Tells tkar to stop processing inputs, closing the input stream.

This is useful in exactly one case: only on MS Windows _and_ when input comes from a pipe (not a socket). Send a `done` message when you are finished sending animation data to tkar. Otherwise, waiting for input that never arrives causes the UI thread to freeze, due to a bug in the VC6 MSVCRT.DLL.

*`exit`*

Exit the tkar process.

*`load FILE`*

Load the specified command file before proceeding with the next command. Any commands take the same effect as if they occurred in the current command sequence. Any number of files may be nested. The file is searched for first assuming that `FILE` is an absolute path and then, if the load command is nested in another file, relative to the dir of that file. The file name may contain spaces; no quotation is needed.

*`echo arg arg ...`*

Echo the arguments back on the output stream from tkar (the same output stream that contains user command messages as described later in this document).


## Window control

*`title TITLE`*

Sets the title of the window to `TITLE`.

*`background COLOR`*

Sets the window background color to <TT>COLOR</tt>. See the section on colors for an explanation of the argument.

*`width X`*

Sets the width (in pixels) of the animation window. (The window can be resized using the mouse.)

*`height Y`*

Sets the height (in pixels) of the animation window. (The window can be resized using the mouse.)

*`window_xy X Y`*

Sets the position of the window on the screen. Positive coordinates denote offset of window from left or top edge of screen. Negative coordinates denote offset from right or bottom edge.

*`zoom_to Z`*

Sets the zoom level of the animation window. A value of 1 means no zoom. A larger value makes objects look bigger. A smaller (positive) value makes objects look smaller. (The zoom can be changed using the mouse or the keyboard--see the help text for the window.)

*`view_at X Y`*

Scroll the canvas so that the point X Y (in canvas coordinates) is at the center of the window.

*`view_id ID`*

Scroll the canvas so that the object with specified id is at the center of the window.

*`follow ID`*

As the animation updates, scroll the window so that the object with specified id is at the center of the window.

*`bounds X_MIN Y_MIN X_MAX Y_MAX`*

Sets the dimensions of the canvas (of which only a portion is visible at a time in the window). The default values are <tt>-3000 -3000 3000 3000</tt>.

*`update`*

Draws all changed objects to the canvas.

*Should be called after each time-step (and after all the `move`, `rot`, etc. commands pertaining to the timestep have been sent) to update the display*.


## Shape definition

A shape definition is used to define how an object is drawn. Each object on the canvas has a shape. A shape is built out of one or more drawing primitives. A shape can reference another shape as a macro and can be parametrized, so that two objects with the same shape may look quite different. A parametrized shape can also be used for an object which changes its geometry or color dynamically.

The basic syntax of a shape definition is:

*`shape SHAPE_NAME PART0 PART1 PART2...`*

This defines a new shape with specified `SHAPE_NAME`, which may be any string without whitespace. The `PART` strings are one or more space-free strings defining the parts of the shape.

The order of the `PART`s is significant: later parts are drawn after, and therefore appear to be above the earlier parts.

The parts can be primitives (discussed below) or other shapes that have already been defined.

### Part Syntax

Each `PART` is of the form:

    partnameARG,ARG,ARG,....

There are no spaces (or line continuations) within the entire `PART`.

The following rules apply:

- `partname` can be the name of a primitive or of another shape. In the latter case, the other shape acts as a _macro_, expanding its own primitives within the shape being defined. For example:
  
      shape foo line0,0,10,10
      shape bar foo

  is equivalent to

      shape foo line0,0,10,10
      shape bar line0,0,10,10

  Any (finite!) number of macros can be nested. Macros may take arguments; see the section on parametrized shapes.

- Arguments are separated from each other by a comma, but no spaces.

- The _positional_ arguments (i.e., the arguments whose meaning derives from their index in the list of arguments) of a primitive are appended to the name of the primitive *without any separating spaces or other characters*. For example:
  
      shape label text0,50

  Positional arguments are almost always coordinates, distances, or angles.

- The _key_-_value_ arguments (i.e., the arguments whose meaning derives from the key string paired with the value), if any, are appended after the positional arguments. They may occur in any order. The key and value are separated by a colon. For example:
  
      shape label text0,50,anchor:c,justify:center,width:40,text:Untitled,fc:0

- In some cases, a single argument must be used to designate a list. In those cases, the "+" character is used to separate the values. For example, as an argument to a line primitive, the following denotes a list of three numbers, 10, 8, and 6, as the value for the arrowshape option:
  
      shape arrow line0,0,*0,0,arrow:last,arrowshape:10+8+6

- If only key-value arguments are present, use a comma to separate the first argument from the name of the shape:
  
      shape car carbox,fc:red

- In some cases, a value might need to include spaces (text, for example). In that case, use a parameter for that value and use the `param` command to set the actual value. See the `text` command entry.

### Parametrized shapes

If a string of the form `*N`, where N is a sequence of digits, occurs in a shape definition, then the shape is parametric. Parameters are not named and can only be referred to by the number `N`.

In an `add` command, the `N`-th parameter supplied with the command is substituted into all places where `*N` appears in the shape definition. For example, the commands:

      shape box rect*0,*0,*1,*1
      add box 3 - 100 30 50 0 5 10

add a box defined by the points 5 5 and 10 10 at position 30 50. (Note that the coordinates 5 5 and 10 10 are in the shape's local coordinate system, whereas the coordinates 30 50 are in the canvas's global coordinates.)

*Note: all of these examples can be entered as standard input to tkar. Just make sure to type* `update` *when you want to see the effect.*

Parametrized shapes can be used as macros inside of shape definitions, in which case their parameters are substituted when the macro is expanded. For example:

      shape box rect*0,*0,*1,*1
      shape two_boxes box-20,-10 box10,20
      add two_boxes 3 - 100 30 50 0

Parameters can be passed to a macro as well as to a primitive:

      shape box rect*0,*0,*1,*1
      shape two_boxes box-20,*0 box*0,20
      add two_boxes 3 - 100 30 50 0 10

Note that the last line above ends with a single parameter value, 10, which is passed to the *0 parameter in `two_boxes`.

Note that not only positional arguments but also key-value arguments can be parametrized:

      shape box rect*0,*0,*1,*1,fc:*2
      add box 3 - 100 30 50 0 5 10 red

## Drawing primitives

Drawing primitives are used only within shape definitions. Primitives cannot be `add`-ed directily to the canvas. (This is because all primitives require some coordinates to outline the shape, but the `add` command only supplies coordinates of the _center_ [or origin] of the shape.)

Since these primitives are implemented directly in terms of TkCanvas primitives, the Tk manual is a helpful reference: http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm. Individual sections are linked to from the sections below.

Points to bear in mind when reading the Tk documentation:

- TkCanvas "items" correspond to Tkar primitives.

- Each primitive takes a list (possibly variable length) of positional arguments, which are typically coordinates.

- Most primitives take, in addition to the positional arguments, key-value pair arguments, which follow the positional arguments and may be in any order. (The Tk documentation refers to the key as an "option".)

- Not all Tk features are supported.

- Tkar "objects" are groupings of multiple TkCanvas items. (The grouping is the effect of having multiple parts in a shape definition.)

- The object ID is handled by Tk as a _tag_.

### Coordinates

The coordinate system while defining shapes always has the following characteristics, regardless of the `--flip` and `--radians` command-line arguments:

- The coordinate system is left-handed: positive x is to the right, positive y is down.

- The origin is the center of the shape (about which the shape will be rotated by the `rot` command).

- Angles are measured in degrees clockwise from the positive x axis.

All primitives in the shape definition use this same coordinate system.

The coordinate system used when _adding_ objects to the canvas or moving them is different, and the orientation and units depend on the `--flip` and `--radians` options.

### Colors

Color can be specified by name or by numeric value, using one of the notations

      #RGB
      #RRGGBB
      #RRRGGGBBB

where each R or G or B is replaced by a hexidecimal digit. Alternately, a decimal integer can be used.

A list of color names is at http://www.tcl.tk/man/tcl8.4/TkCmd/colors.htm. Examples:

      green
      DarkOrchid2
      #EECC66
      #F0F

### Generic options

The following options apply to most primitives (each option has a shortcut, which is listed second).

#### *`fill:COLOR`*

#### *`fc:COLOR`*

Set the fill color of the primitive.

#### *`outline:COLOR`*

#### *`oc:COLOR`*

Set the outline color of the primitive.

#### *`width:WIDTH`*

#### *`wi:WIDTH`*

Set the line (or outline) width.

#### *`dash:DASH_TYPE`*

#### *`da:DASH_TYPE`*

Set the dash type for the line (or outline). The value can be an integer or a string. See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M27. For example,

      da:48

produces a nice dashed line to represent the lines between lanes in a roadway. The 4 means 4 pixels without color; the 8 means 8 pixels with the specified outline color. Tk accepts any sequence of digits, but not all platforms support all sequences.

#### *`stipple:STIPPLE_TYPE`*

#### *`st:STIPPLE_TYPE`*

Set the stipple type for the region. See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M111. (This is not very useful.)

### Primitives

The primitives are the basic shapes from which user-defined shapes are built.

#### arc

*`arcX,Y,W,H,key:val...`*

Draw an arc-based shape, which may be a pieslice, a chord region (between a chord and the arc), or a true arc (segment of a circle or oval).

The point `X Y` is the center, `W` is width, `H` is height.

*Note that this differs from Tk's arc command,* whose inputs are two points: "two diagonally opposite corners of a rectangular region enclosing the oval". It's generally easier to work with center and height/width. Rotation may look strange if width != height (this is because the rectangular region is still used internally, and Tk doesn't rotate rectangles).

Options (in addition to the generic options) are:

option| values
------| ------
`extent:angle`|  angular span of the arc
`start:angle`|   angle of rotation of the arc, measured _counterclockwise_ from the positive x-axis
`style:sty`|     `pieslice`, `chord`, or `arc`

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M119

#### line

*`lineX1,Y1,X2,Y2...,key:val...`*

Draw a line or other one-dimensional curve.

The curve follows the sequence of points `X1 Y1, X2 Y2, ....`

Options (in addition to the generic options) are:

option| values
------| ------
`arrow:val`|            `none`, `first`, `last`, or `both`
`arrowshape:N+N+N`|     three numbers separated by a \+ character(*)
`capstyle:style`|       `butt`, `projecting`, `round`
`joinstyle:style`|      `miter`, `bevel`, `round`
`smooth:bool`|          `true` or `false`
`splinesteps:number`|   number of smoothing steps

(*) Paraphrasing the Tk documentation on arrowshape: The first number gives the distance along the line from the neck of the arrowhead to its tip. The second number gives the distance along the line from the trailing points of the arrowhead to the tip, and the third number gives the distance from the outside edge of the line to the trailing points.

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M139

#### oval

*`ovalX1,Y1,X2,Y2,key:val...`*

Draws a circle or oval.

The points `X1 Y1` and `X2 Y2` define the diagonally opposite corners of the bounding box of the oval.

There are no options other than the generic options.

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M146

#### rect

*`rectX1,Y1,X2,Y2,key:val...`*

Draws a rectangle.

The points `X1 Y1` and `X2 Y2` define the diagonally opposite corners.

*Note: A rect is not rotatable. Use a polygon instead.*

There are no options other than the generic options.

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M151

#### poly

*`polyX1,Y1,X2,Y2,...key:val...`*

Draw a polygon or closed curve.

The edges or curve segments follow the sequence of points `X1 Y1, X2 Y2, ....` and the last point is connected to the first.

Options (in addition to the generic options) are:

option| values
------| ------
`joinstyle:val`|        `miter`, `bevel`, or `round`
`smooth:bool`|          `true` or `false`
`splinesteps:number`|   number of smoothing steps

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M147

#### text

*`textX,Y,key:val...`*

Draws text string at the indicated location. (Text is not rotatable.)

Options (in addition to the generic options) are:

option| values
------| ------
`anchor:anchorPos`|     `center`, `n`, `nw`, ...
`font:fontName`|        font name
`justify:how`|          `left`, `right`, or `center`
`text:string`|          string to display(**)
`width:lineLength`|     length at which line is wrapped

(**) text with embedded spaces can be specified only via a param command.

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M152

#### image

*`imageX,Y,key:val...`*

Draws an image from a file at the indicated location. (An image is not rotatable.)

Tk supports only GIF, by default, though Tk can be extended to support other formats.

Options (in addition to the generic options) are:

option| values
------| ------
`anchor:anchorPos`|     `center`, `n`, `nw`, ...
`image:imageFileName`|  file name of the gif file 

Note that tkar is smart about caching image data. The file is read once, no matter how many times it is referenced in different shapes.

See http://www.tcl.tk/man/tcl8.4/TkCmd/canvas.htm#M134

#### polybox

*`polyboxDX,DY`*

Draws a rotatable rectangle extending `DX` units on each side of the Y axis, and extending `DY` units above and below the X axis.

Not a Tk primitive, but a simple poly-derived shape that can be used to draw a rectangle with rotation. This doesn't have an offset parameter. If the rectangle needs to be offset from the shape origin, use a polygon.

There are no options other than the generic options.


## Object manipulation

*`add SHAPE_NAME ID FLAGS LAYER X Y R [PARAM0 PARAM1 ...]`*

Add an object to the canvas. The shape of the object is determined by the SHAPE_NAME, which must have been defined using the `shape` command.

The `ID` must be a unique nonnegative integer in the range 0..2^32-1. If an object with that `ID` already exists (with any shape), the new object will replace the existing object.

`FLAGS` is a string which is currently unused but will be used to set various flags (such as clickable and draggable).

`LAYER` is a nonnegative integer in the range 0..2^32-1 which specifies the drawing order. Higher numbers cause objects to be drawn on top of objects with lower layer numbers.

The `X` `Y` and `R` parameters are floating point signed decimal numbers describing the global coordinates and rotation of the object. These numbers define the origin and rotation that are used to draw the primitives of `SHAPE_NAME`. See the `moveto` and `rot` commands.

The `PARAM` parameters are as described for the `param` command. A `PARAM` given in the add command cannot include spaces. However, a `PARAM` given with the `param` command _can_ include spaces.

Only the `PARAM` fields are optional--all others are required.

*`del ID`*

Deletes the object with the specified `ID` from the canvas.

*`delete_all`*

Deletes all objects. Does not delete shape definitions.

*`moveto ID X Y`*

Move the object with the specified `ID` to canvas coordinates `X` `Y`. (The coordinate system is left handed unless the --flip command line option is used.)

*`rot ID R`*

Rotate the object with the specified `ID` to `R` degrees (absolute, not relative to current rotation). (Uses radians if the --radians command line option is given.)

*`param ID N VALUE`*

Set the N-th parameter (index starting from 0) of object `ID` to `VALUE`. Params can be used to control many aspects of a shape, including colors, dimensions, offsets, line characteristics, boolean flags, text, etc.

It is not possible to modify the flags, layer, or shape--use an add command to do that (if you add an object with the same ID as before, the old object will be deleted).

*`scale_obj ID xf yf`*

Scales the object in the x dimension by a x factor of `xf` and in the y dimension by a factor of `yf`. A factor of 1.0 means no scaling. A factor of 2.0 means double size, and so on.

## Abbreviations

Most commands have abbreviated or alternate versions. The following list shows all commands with alternates indicated by a | character and abbreviations indicated by a > character (for example, update can be abbreviated as "u" or "up").

      a>dd
      d>el>ete
      m>ove>to
      r>ot>ate
      p>ar>am
      s>h>ape
      u>p>date
      title
      background|bg
      height
      width
      zoom_to|zoom
      view_at|view
      view_id
      wait
      follow
      done
      bound>s
      load
      exit
      delete_all
      scale>_obj
      echo
      window_xy


## Tkar outputs

Tkar sends outputs back on the stream to the controlling process. Typically this stream is either the stdout of tkar or a socket. Tkar also writes output to stderr.

### User command messages

Tkar sends back outputs as the result of user interaction. These output commands can be used to update the controlling program's model of the objects, or to implement simple GUI widgets (buttons, sliders, control points, etc.).

*`drag DRAG_ID X Y`*

User has dragged the object with id `DRAG_ID` to `X` `Y`.

*`drop DRAG_ID [TARGET_ID]`*

User has dropped the object with id `DRAG_ID`. If `TARGET_ID` is given, the object was dropped on top of the object with id `TARGET_ID`.

*`click ID`*

User has clicked on object with id `ID`.

*`</tt>doubleclick ID</b>

User has doubleclicked on object with id `ID`.

*`quit`*

User has pressed Ctrl-q

*`update`*

Update cycle has finished. This message is sent back out by tkar once for every update command that comes into tkar. This is useful to keep the two programs, tkar and the controlling program, in sync.

### Error messages

Error messages are also sent back to the controlling process on the stream.

### stderr messages

Tkar uses stderr as a second destination for outputs, separate from the stream used by the controlling process. This is useful for diagnostics and logging. If the -v (verbose) command-line option is given, the stderr output copies all input commands. This can be used to create a replayable record of the animation. The stderr stream also includes error messages.

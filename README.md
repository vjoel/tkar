# Tkar -- Tk-based animation process and protocol

The Tkar animator aims to do one thing well: listen to an incoming stream of data and animate it in a 2D canvas. User interaction is streamed back out.

Additional documentation:

* [protocol](doc/protocol.md)
* [FAQ](doc/faq.md)

## Overview

Tkar is a Tk/ruby-based animation program using TkCanvas. It accepts command input from stdin or a socket. Commands may define parametrized shapes, place them on the canvas, move and rotate them, change parameters, etc. User interaction events (click, drag, etc) are sent back on the socket or stdout. The canvas can be resized, scrolled, zoomed, and tracked to an object.

### Graphical constructs

* Shapes include: arc, oval, polygon, line, curve, text, bitmap. 

* Parameters include color/pattern of border/area, arrowheads, splines, line dot/dash/width, text font, etc.

* Can group, layer, rotate, move, and scale objects

### Tkar command summary

_shape_:: define shape in terms of primitives (Tk Canvas objects). Shape may expose any Tk parameters (e.g, colors, lengths of poly sides)

_add_:: add object to canvas with specified shape, layer, position, rotation, params

_move_, _rotate_, _scale_, _delete_:: operate on existing object

_param_:: change param value of an object (e.g. change color or geometry over time; change arrow shape because endpoint moves)

utilities:: _wait_ (playback with specified frame rate), _update_ (end of time step), set window _params_ (color, size, zoom), _follow_ a specified object, _load_ file (like #include)

### User interaction

* Use keys and mouse to zoom, pan/scroll, select, double-click, drag, drop, etc.

* User commands are sent back over stream to controlling process, e.g. "drag 2 140.0 259.0" and "drop 2 7" ("2" and "7" are object ids)


## Installation

### Prerequisites

#### Tcl/Tk

For windows: http://www.activestate.com/Products/ActiveTcl/

For linux, just use your distribution's package tool to install tcl. However, you may need to make sure that ruby and linux both use (or do not use) the pthread library.

#### Ruby

For windows: http://rubyforge.org/projects/rubyinstaller/

For other platforms: http://www.ruby-lang.org

### Gem installation

  gem install tkar

Alternately, you can download the source code (tar ball or git repo) and run it in place using the <tt>--local-lib</tt> command line option

  bin/tkar --local-lib


## Usage

### Command line

See the -h command line option for details on running tkar.

Examples are available with the source code--read the comments to see how to run.

### Tkar window

Press the "h" key for on-line help using the tkar window.

### Protocol

See [protocol](doc/protocol.md) for details on the protocol and writing shape files.

### Integrating tkar with other applications

There are three transport options:

1. Over pipe

      cat data | tkar

  or

      program | tkar

  - unidirectional (no mouseclick feedback to program)

  - output messages simply go to stdout

  - easy to write filters this way

2. Over TCP socket

      tkar [<ipaddr>] <port>

  - bidirectional; client can block waiting for update to finish

  - remote host possible, using ipaddr=="localhost"

  - if port is 0, lets OS choose port and prints it to stderr

  - can still write filters by using netcat

3. Over unix domain socket

      tkar /path/to/socket

  - bidirectional; client can block waiting for update to finish

  - faster than TCP (but unix/linux only)

Note that tkar has a -c option which tells it to be the socket client rather than the server. This is useful when your main program needs to choose the port, for example.

## Tkar and Simulink

Tkar can be interfaced with Simulink. Tkar appears in a simulink model as a block to which can be wired to any number of data sources that drive objects in the animation. You can have several tkar blocks. Think of tkar as the animation version of the built-in plotting block. (Simulink's built-in animation capabilities are bad.)

An additional set of C files need to be compiled as a Simulink extension. Contact author for details.

## Author

Copyright 2006-2014, Joel VanderWerf, mailto:vjoel@users.sourceforge.org

## License

License is BSD. See [COPYING](COPYING).

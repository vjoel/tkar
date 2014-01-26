# Design Decisions

## what is tkar trying to be?

The gnuplot of animation -- a quick and dirty way to get data (stream or file) into a window to see what is happening.

## why Tk?

Tcl/Tk is widely available, and the Ruby/Tk interface is a standard part of ruby.

## why TkCanvas?

TkCanvas has easy access to relatively high-level 2D vector graphics constructs, such as groups, layers, splines, fonts, icons, zoom, and scroll. Plus, it supports mouse/keyboard operations, dialogs, and so on.

## why not just write code in Ruby/Tk instead of stream to tkar?

1. Because you may not want to write your code in the Tk framework. Maybe you're using a different gui, or not a gui at all.

2. Tkar handles a lot of window / process complications such as drag-and-drop and following (see canvas.rb and window.rb for details).

3. You can write upstream code in any language, or even just cat from a file.

4. You can distribute processing: take advantage of 2 cpus, or even 2 hosts across a network.

## why not HTML 5 canvas, other gui canvas, or Processing?

Those are heavyweight and add more dependencies (browser, java), and in some cases still lack some of the features of TkCanvas. Tkar is light enough that you can run several instances at once even on resource limited machines.

## why not opengl?

It would be more work to get the diagram and user interaction stuff. Anyway, it's overkill.

## why a special protocol, rather than ruby/tk method calls serialized as text?

The protocol is not a programming language: there are no variables, functions, loops, etc. There are only macros. It is very simple, which makes it much easier to emit from other languages than ruby, and less prone to programming errors.

## why is the protocol so ugly?

It's not meant to be written by hand. You wouldn't write http headers by hand, would you?

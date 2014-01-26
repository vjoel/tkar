module Tkar
  class HelpWindow < TkToplevel
    def self.show
      if @help_window
        @help_window.destroy
      end
      @help_window = new
    end
    
    def initialize(*)
      super
      
      title("Tkar Help")
      iconname("tkar help")

      frame = TkFrame.new(self){|frame|
        pack('side'=>'top', 'expand'=>'yes', 'fill'=>'both')
      }
      
      text = TkText.new(frame){|t|
        setgrid 'true'
        width  72
        height 32
        wrap 'word'
        
        TkScrollbar.new(frame) {|s|
          pack('side'=>'right', 'fill'=>'y')
          command proc{|*args| t.yview(*args)}
          t.yscrollcommand proc{|first,last| s.set first,last}
        }
        pack('expand'=>'yes', 'fill'=>'both')

        st_fixed = TkTextTag.new(t,
          'font'=>'-*-Courier--R-Normal--*-120-*-*-*-*-*-*')
        st_bold = TkTextTag.new(t,
          'font'=>'-*-Courier-Bold-O-Normal--*-120-*-*-*-*-*-*')
        st_big = TkTextTag.new(t,
          'font'=>'-*-Courier-Bold-R-Normal--*-140-*-*-*-*-*-*')
        st_h1 = st_verybig = TkTextTag.new(t,
          'font'=>'-*-Helvetica-Bold-R-Normal--*-240-*-*-*-*-*-*')
        st_h2 = TkTextTag.new(t,
          'font'=>'-*-Helvetica-Bold-R-Normal--*-160-*-*-*-*-*-*')
        st_small = TkTextTag.new(t,
          'font'=>'-Adobe-Helvetica-Bold-R-Normal-*-100-*')
        
        st_color1 = TkTextTag.new(t, 'background'=>'#a0b7ce')
        st_color2 = TkTextTag.new(t, 'foreground'=>'red')
        st_raised = TkTextTag.new(t, 'relief'=>'raised', 'borderwidth'=>1)
        st_sunken = TkTextTag.new(t, 'relief'=>'sunken', 'borderwidth'=>1)

        st_bgstipple = TkTextTag.new(t, 'background'=>'black', 
                                            'borderwidth'=>0, 
                                            'bgstipple'=>'gray12')

        st_fgstipple = TkTextTag.new(t, 'fgstipple'=>'gray50')
        st_underline = TkTextTag.new(t, 'underline'=>'on')
        st_overstrike = TkTextTag.new(t, 'overstrike'=>'on')
        st_right  = TkTextTag.new(t, 'justify'=>'right')
        st_center = TkTextTag.new(t, 'justify'=>'center')
        st_super = TkTextTag.new(t, 'offset'=>'4p', 'font'=>'-Adobe-Courier-Medium-R-Normal--*-100-*-*-*-*-*-*')
        st_sub = TkTextTag.new(t, 'offset'=>'-2p', 'font'=>'-Adobe-Courier-Medium-R-Normal--*-100-*-*-*-*-*-*')
        st_margins = TkTextTag.new(t, 'lmargin1'=>'12m', 'lmargin2'=>'6m',
                                          'rmargin'=>'10m')
        st_spacing = TkTextTag.new(t, 'spacing1'=>'10p', 'spacing2'=>'2p',
                                          'lmargin1'=>'12m', 'lmargin2'=>'6m',
                                          'rmargin'=>'10m')

        
        insert('end', "\nTkar Quick Reference", [st_center, st_h1])
        
        insert('end', "\n\nKey commands", [st_h2])

        insert('end', "\n
    command                  effect
    ----------------------------------------------------
    <right-arrow>            scroll right
    <left-arrow>             scroll left
    <up-arrow>               scroll up
    <down-arrow>             scroll down
    
    <ALT-right-arrow>        scroll right one pixel
    <ALT-left-arrow>         scroll left one pixel
    <ALT-up-arrow>           scroll up one pixel
    <ALT-down-arrow>         scroll down one pixel
    
    <CTRL-up-arrow>          zoom out
    <CTRL-down-arrow>        zoom in
    
    h                        show help window(*)
    CTRL-q                   quit Tkar
        ", st_fixed)

        insert('end', "\n\n(*) The '?' button in the lower right corner also bings up the help window.")
        
        insert('end', "\n\nMouse commands", [st_h2])

        insert('end', "\n
    command                  effect
    ----------------------------------------------------
    <button-1-drag>          drag an object(*)
    <CTRL-btn-1>             select object to follow(**)
    <button-2-drag>          zoom in or out
    <button-3-drag>          scroll
    <CTRL-btn-3-drag>        scroll faster
    <mouse-wheel>            zoom
    <CTRL-mouse-wheel>       zoom faster
    <hover>                  highlight all parts of object
        ", st_fixed)
        
        insert('end', "\n\n(*) If no object is under the mouse, this can be used to scroll the view by moving the mouse outside the visible area.")
        
        insert('end', "\n\n(**) If no object is under the mouse, this clears the previously selected object to follow (if any) and centers the display at the selected point. If the object selected to be followed is selected a second time, the object is no longer followed.")
        
        insert('end', "\n\n In addition, some mouse commands cause output to be sent back to the controlling process that can be used to manipulate its own representation of the objects:")

        insert('end', "\n
    command                  text sent to master process
    ----------------------------------------------------
    <click>                  click <ID>
    <doubleclick>            doubleclick <ID>
    <button-1-drag>          drag <ID> <x> <y>
    <button-1-drop>          drop <ID> <target-ID>
        ", st_fixed)
        
        insert('end', "\n\nCommand-line usage", [st_h2])
        insert('end', "\
\n\n
  tkar [-b] [addr] [port]

    Start a tkar animation process. Its inputs and outputs are one of:

      stdin/stdout: this is the default

      TCP socket:   if port is given (addr default is 127.0.0.1)

      UNIX socket:  if addr only is given

    The -b switch turns on binary protocol mode, otherwise uses ascii.
    See docs for details.

    Additional switches:

      -h            this help

      -c            act as client instead of server [socket cases only]

      --local-lib   tells bin/tkar to use the lib dir at ./lib
", st_fixed)

        insert('end', "\n\nRun tkar with the -h option to get the most up-to-date list of command line options.")

        insert('end', "\n\nAuthor", [st_center, st_h1])
        insert('end', "\n\nJoel VanderWerf, vjoel@users.sourceforge.net")
        
        insert('end', "\n\nLicense", [st_center, st_h1])
        insert('end', "\
\n\n
Use of Tkar is subject to the Ruby license:
http://www.ruby-lang.org/en/LICENSE.txt

Copyright (c) 2006-2009, Joel VanderWerf
")
        
        state 'disabled'
      }
    end
  end
end

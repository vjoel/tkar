require 'tk'
require 'tkar/canvas'
require 'tkar/help-window'

module Tkar
  class Window
    attr_reader :canvas
    
    HELP_ICON = TkPhotoImage.new(
      :format => 'GIF',
      #:file => 'sample/help.gif'
      :data => %{       
        R0lGODlhCAAIAMIEAKK1zQAAAIQAAP//AP///////////////yH5BAEKAAcA\nLAAAAAAIAA
        gAAAMQSBQcug6qON9kFtud6dNEAgA7\n
      }
    )

    ## cmds to show grid, save image, make movie
    ## preferences

    def initialize root, opts
      @flip = opts["flip"]
      
      canvas_frame = TkFrame.new(root) do
        pack 'fill'=>'both', 'expand'=>true
        background "lightgray"
      end
      TkGrid.rowconfigure(canvas_frame, 0, 'weight'=>1, 'minsize'=>0)
      TkGrid.columnconfigure(canvas_frame, 0, 'weight'=>1, 'minsize'=>0)

      @canvas = canvas = Tkar::Canvas.new(canvas_frame) do
        @bounds = [-3000, -3000, 3000, 3000]
        background "gray"
        relief "sunken"
        width 100; height 100 ## user prefs?
        configure :scrollregion => @bounds
        xscrollincrement 1
        yscrollincrement 1
        grid(:in => canvas_frame,
          :row => 0, :column => 0, 
          :rowspan => 1, :columnspan => 1, :sticky => :news)
        @root = root
      end
      
      xscroll = TkScrollbar.new(canvas_frame) do
        background 'darkgray'
        width 10
        relief "sunken"
        command do |*args|
          canvas.xview *args
        end
        grid(:in => canvas_frame,
          :row => 1, :column => 0, 
          :rowspan => 1, :columnspan => 1, :sticky => :news)
        orient 'horiz'
      end

      yscroll = TkScrollbar.new(canvas_frame) do
        background 'darkgray'
        width 10
        relief "sunken"
        command do |*args|
          canvas.yview *args
        end
        grid(:in => canvas_frame,
          :row => 0, :column => 1, 
          :rowspan => 1, :columnspan => 1, :sticky => :news)
        orient 'vertical'
      end

      TkButton.new(canvas_frame) do
        image HELP_ICON
        compound :none
        relief "flat"
        command {HelpWindow.show}
        grid(:in => canvas_frame,
          :row => 1, :column => 1, 
          :rowspan => 1, :columnspan => 1, :sticky => :news)
      end

      canvas.xscrollcommand do |first, last|
        xscroll.set(first, last)
      end
      canvas.yscrollcommand do |first, last|
        yscroll.set(first, last)
      end
      
      root.bind "Key-Right" do
        canvas.xview "scroll", 10, "units"
      end

      root.bind "Key-Left" do
        canvas.xview "scroll", -10, "units"
      end

      root.bind "Key-Down" do
        canvas.yview "scroll", 10, "units"
      end

      root.bind "Key-Up" do
        canvas.yview "scroll", -10, "units"
      end

      root.bind "Alt-Key-Right" do
        canvas.xview "scroll", 1, "units"
      end

      root.bind "Alt-Key-Left" do
        canvas.xview "scroll", -1, "units"
      end

      root.bind "Alt-Key-Down" do
        canvas.yview "scroll", 1, "units"
      end

      root.bind "Alt-Key-Up" do
        canvas.yview "scroll", -1, "units"
      end

      root.bind "Control-Up" do
        canvas.zoom_by 0.75
      end
      
      root.bind "Control-Down" do
        canvas.zoom_by 1.5
      end
      
      root.bind "Key-h" do
        HelpWindow.show
      end

      root.bind "Control-q" do
        exit
      end
      
      at_exit do
        message_out "quit"
      end
      
      drag_start = drag_dx = drag_dy = drag_tkaroid = click_tkaroid = nil
      drop_target = nil
      drag_timer = nil
      
      drag_proc = proc do |x, y|
        if drop_target
          drop_target.decolorize(canvas)
          drop_target = nil # we'll check below if it still is
        end

        tkaroid = canvas.current_tkaroid
        if tkaroid and tkaroid.draggable?
          drag_tkaroid = tkaroid
          x0, y0 = drag_start

          drag_dx = (x-x0)/canvas.zoom
          drag_dy = (y-y0)/canvas.zoom
          new_x, new_y = tkaroid.x + drag_dx, tkaroid.y + drag_dy
          canvas.moveto(tkaroid.id, new_x, new_y)
          msg_x, msg_y = new_x, new_y
          if @flip
            msg_y = -msg_y
          end
          message_out "drag #{tkaroid.id} #{msg_x} #{msg_y}"
          tkaroid.update(canvas)
          tkaroid.drag_colorize(canvas)
          drag_start = [x, y]

          cx = canvas.canvasx(x)
          cy = canvas.canvasy(y)
          closest = canvas.find_closest(cx, cy, 0, "all") # start at top
          tags = closest.map {|prim|prim.tag}.flatten
          if tags.include? "current"
            closest = canvas.find_closest(cx, cy, 0, "current")
            tags = closest.map {|prim|prim.tag}.flatten
          end

          unless tags.include? "current"
            tkar_id = tags.grep(/^tkar\d+$/).first[/\d+/].to_i
            tgt = canvas.get_object tkar_id
            if tgt.drop_target? and tgt != drag_tkaroid
              drop_target = tgt
              drop_target.hover_colorize(canvas)
            end
          end
        end
      end

      drag_outside = proc do |x, y|
        drag_timer = TkTimer.new(50) do
          # scroll canvas if out of window if needed
          width = canvas.current_width
          height = canvas.current_height
          units = 10
          xsi = canvas.cget("xscrollincrement")*units
          ysi = canvas.cget("yscrollincrement")*units

          if x < 0
            canvas.xview "scroll", -units, "units"
            x = -xsi
            if drag_start
              x0,y0 = drag_start
              drag_start = [x0 + xsi, y0]
            end
          end

          if x > width
            canvas.xview "scroll", units, "units"
            x = width + xsi
            if drag_start
              x0,y0 = drag_start
              drag_start = [x0 - xsi, y0]
            end
          end

          if y < 0
            canvas.yview "scroll", -units, "units"
            y = -ysi
            if drag_start
              x0,y0 = drag_start
              drag_start = [x0, y0 + ysi]
            end
          end

          if y > height
            canvas.yview "scroll", units, "units"
            y = height + ysi
            if drag_start
              x0,y0 = drag_start
              drag_start = [x0, y0 - ysi]
            end
          end

          drag_proc[x,y] if drag_start
        end
        drag_timer.start
      end

      canvas.bind('B1-Motion', '%x %y') do |x, y|
        if drag_timer
          drag_timer.stop
          drag_timer = nil
        end

        if x >= 0 and x <= canvas.current_width and
           y >= 0 and y <= canvas.current_height
          drag_proc[x,y] if drag_start
        else
          drag_outside[x,y] if drag_start
        end
      end

      canvas.bind('B1-ButtonRelease', '%x %y') do |x, y|
        if drag_timer
          drag_timer.stop
          drag_timer = nil
        end

        if drag_tkaroid
          drag_tkaroid.hover_colorize(canvas)

          if drop_target
            message_out "drop #{drag_tkaroid.id} #{drop_target.id}"
            drop_target.decolorize(canvas)
          else
            message_out "drop #{drag_tkaroid.id}"
          end

          # if mouse is now over a NEW object
          #   leave the old object
          #   enter the new object
          # (since Tk doesn't seem to generate leave and enter events)
          cx = canvas.canvasx(x)
          cy = canvas.canvasy(y)
          closest = canvas.find_closest(cx, cy, 0, "all") # start at top
          tags = closest.map {|prim|prim.tag}.flatten
          tkar_id = tags.grep(/^tkar\d+$/).first[/\d+/].to_i
          top_tkaroid = canvas.get_object tkar_id
          if top_tkaroid != drag_tkaroid
            drag_tkaroid.update(canvas)
            top_tkaroid.hover_colorize(canvas) if top_tkaroid
          end
          
        elsif click_tkaroid
          click_tkaroid.hover_colorize(canvas)
        end

        drag_start = drag_dx = drag_dy = drag_tkaroid = drop_target = nil
        click_tkaroid = nil
      end
      
      zoom_start = nil
      canvas.bind('2', '%x %y') {|x,y| zoom_start = y}
      canvas.bind('B2-Motion', '%x %y') {|x,y|
        canvas.zoom_by(1 + (y - zoom_start)/500.0)
        zoom_start = y
      }
      
      canvas.bind('3', '%x %y') {|x,y| canvas.scan_mark(x,y)}
      canvas.bind('B3-Motion', '%x %y') {|x,y| canvas.scan_dragto(x,y,1)}
      canvas.bind('Control-B3-Motion', '%x %y') {|x,y|
        canvas.scan_dragto(x,y,3)}
      
      small_zoom = 0.95
      large_zoom = 0.75
      
      canvas.bind('4') {canvas.zoom_by small_zoom}
      canvas.bind('5') {canvas.zoom_by 1/small_zoom}

      # For X windows:
      canvas.bind('Control-4') {canvas.zoom_by large_zoom}
      canvas.bind('Control-5') {canvas.zoom_by 1/large_zoom}
      
      # For MSWindows:
      root.bind('MouseWheel', "%D") { |delta|
        canvas.zoom_by small_zoom**(delta/120)
      }
      root.bind('Control-MouseWheel', "%D") { |delta|
        canvas.zoom_by large_zoom**(delta/120)
      }

      canvas.bind('Control-1', '%x %y') do |x, y|
        tkaroid = canvas.current_tkaroid
        if tkaroid
          # handled in itembind('Control-1')
        else
          canvas.follow(nil)
          canvas.view_at_screen(x,y)
        end
      end
      
      canvas.itembind('all', '1', '%x %y') do |x, y|
        tkaroid = canvas.current_tkaroid
        if tkaroid
          if tkaroid.draggable?
            drag_start = [x, y]
            tkaroid.drag_colorize(canvas)
          end
          message_out "click #{tkaroid.id}"
        end
        click_tkaroid = tkaroid
      end

      canvas.itembind('all', 'Control-1', '%x %y') do |x, y|
        tkaroid = canvas.current_tkaroid
        if tkaroid
          if tkaroid.id == canvas.follow_id
            canvas.follow(nil)
          else
            canvas.follow(tkaroid.id)
            canvas.view_followed_obj
          end
        end
      end
      
      canvas.itembind('all', 'Double-1') do
        tkaroid = canvas.current_tkaroid
        message_out "doubleclick #{tkaroid.id}" if tkaroid
      end

      canvas.itembind('all', 'Any-Enter') do
        unless drag_start
          tkaroid = canvas.current_tkaroid
          if tkaroid
            tkaroid.hover_colorize(canvas)
          end
        end
      end
      
      canvas.itembind('all', 'Any-Leave') do
        tkaroid = canvas.current_tkaroid
        tkaroid.decolorize(canvas) if tkaroid
      end
    end
    
    def message_out msg
      @message_out[msg] if @message_out
    end
    
    def def_message_out(&bl)
      @message_out = bl
    end
  end
end

module Tkar
  module Primitives
    module_function
    
    SHORTCUTS = {
     "fc"  => "fill",
     "oc"  => "outline",
     "wi"  => "width",
     "da"  => "dash",
     "st"  => "stipple",
    }
    
    def handle_shortcuts key
      SHORTCUTS[key] || key
    end
    
    @color_str = {}

    def color_str col
      @color_str[col] ||=
        begin
          s = col.to_s(16).rjust(6, "0")
          "##{s}"
        rescue
          col # assume col is a color name
        end
    end
    
    @dash_val = {}

    def dash_val val
      @dash_val[val] ||= val.is_a?(Integer) ? val.to_s.split("") : val
    end

    # handles the following options:
    #
    #  fill    
    #  outline 
    #  width   
    #  dash    
    #  stipple 
    def handle_generic_config(config, params, key_args)
      fc, oc, wi, da, st =
        key_args.values_at(*%w{fill outline width dash stipple})
      if fc
        ## skip if we saw this one before?
        val = fc[params] rescue fc
        config[:fill] = color_str(val)
      end
      if oc
        val = oc[params] rescue oc
        config[:outline] = color_str(val)
      end
      if wi
        config[:width] = wi[params] rescue wi
      end
      if da
        val = da[params] rescue da
        config[:dash] = dash_val val
      end
      if st
        config[:stipple] = st[params] rescue st
        ## how to use "@filename" to load file once and then use bitmap name?
      end
    end
    
    # arcX,Y,W,H,key:val...
    #
    # (X,Y) is center, W is width, H is height.
    # This differs from Tk because it's better!
    # Rotation may look strange if width != height
    #
    #  extent angle
    #  start angle
    #  style sty  (pieslice, chord, or arc)
    def arc args, key_args
      extent, start, style = key_args.values_at(*%w{extent start style})
      
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        cx, cy, width, height = args.map {|arg| arg[params] rescue arg}

        rcx = x + cx * cos_r - cy * sin_r
        rcy = y + cx * sin_r + cy * cos_r
        
        coords = [
          rcx - width,  rcy - height,
          rcx + width,  rcy + height ]
        
        ## possible to skip below if no changes?
        config = {}
        handle_generic_config(config, params, key_args)
        
        if extent
          config[:extent] = extent[params] rescue extent
        end
        if start
          config[:start] = start[params] rescue start
          config[:start] -= tkaroid.r * RADIANS_TO_DEGREES
        end
        if style
          config[:style] = style[params] rescue style
        end

        [TkcArc, coords, config]
      end
    end
    
    # lineX1,Y1,X2,Y2...,key:val...
    #
    #  arrow where (none, first, last, both)
    #  arrowshape shape
    #  capstyle style (butt, projecting, round)
    #  joinstyle style (miter, bevel, round)
    #  smooth smoothMethod (true or false)
    #  splinesteps number
    def line args, key_args
      arrow, arrowshape, capstyle, joinstyle, smooth, splinesteps =
      key_args.values_at(
        *%w{arrow arrowshape capstyle joinstyle smooth splinesteps})

      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        coords = []
        points = args.map {|arg| arg[params] rescue arg}
        points.each_slice(2) do |xv, yv|
          coords << x + xv * cos_r - yv * sin_r
          coords << y + xv * sin_r + yv * cos_r
        end
        
        config = {}
        handle_generic_config(config, params, key_args)
        
        if arrow
          config[:arrow] = arrow[params] rescue arrow
        end
        if arrowshape
          val = arrowshape[params] rescue arrowshape
          val = val.split("+").map{|s| Integer(s)}
          config[:arrowshape] = val
        end
        if capstyle
          config[:capstyle] = capstyle[params] rescue capstyle
        end
        if joinstyle
          config[:joinstyle] = joinstyle[params] rescue joinstyle
        end
        if smooth
          config[:smooth] = smooth[params] rescue smooth
        end
        if splinesteps
          config[:splinesteps] = splinesteps[params] rescue splinesteps
        end

        [TkcLine, coords, config]
      end
    end
    
    # ovalX1,Y1,X2,Y2,key:val...
    # standard keys
    def oval args, key_args
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        coords = []
        points = args.map {|arg| arg[params] rescue arg}
        points.each_slice(2) do |xv, yv|
           coords << x + xv * cos_r - yv * sin_r
           coords << y + xv * sin_r + yv * cos_r
        end
        
        config = {}
        handle_generic_config(config, params, key_args)

        [TkcOval, coords, config]
      end
    end
    
    # rectX1,Y1,X2,Y2,key:val...
    # standard keys
    def rect args, key_args
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        coords = []
        points = args.map {|arg| arg[params] rescue arg}
        points.each_slice(2) do |xv, yv|
           coords << x + xv * cos_r - yv * sin_r
           coords << y + xv * sin_r + yv * cos_r
        end
        
        config = {}
        handle_generic_config(config, params, key_args)

        [TkcRectangle, coords, config]
      end
    end
    
    # polyX1,Y1,X2,Y2,...key:val...
    #
    #  joinstyle style (miter, bevel, round)
    #  smooth smoothMethod (true or false)
    #  splinesteps number
    def poly args, key_args
      joinstyle, smooth, splinesteps =
      key_args.values_at(*%w{joinstyle smooth splinesteps})

      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        coords = []
        points = args.map {|arg| arg[params] rescue arg}
        points.each_slice(2) do |xv, yv|
           coords << x + xv * cos_r - yv * sin_r
           coords << y + xv * sin_r + yv * cos_r
        end
        
        config = {}
        handle_generic_config(config, params, key_args)

        if joinstyle
          config[:joinstyle] = joinstyle[params] rescue joinstyle
        end
        if smooth
          config[:smooth] = smooth[params] rescue smooth
        end
        if splinesteps
          config[:splinesteps] = splinesteps[params] rescue splinesteps
        end

        [TkcPolygon, coords, config]
      end
    end
    
    # textX,Y,key:val...
    #
    #  anchor anchorPos (center, n, nw, ...)
    #  font fontName
    #  justify how (left, right, or center)
    #  text string (**)
    #  width lineLength
    #
    # (**) text with embedded spaces can be specified only via a param command 
    def text args, key_args
      anchor, font, justify, text =
      key_args.values_at(*%w{anchor font justify text})
       # width handled by handle_generic_config
      
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        xv, yv = args.map {|arg| arg[params] rescue arg}
        coords = [
          x + xv * cos_r - yv * sin_r,
          y + xv * sin_r + yv * cos_r
        ]
        
        config = {}
        handle_generic_config(config, params, key_args)

        if anchor
          config[:anchor] = anchor[params] rescue anchor
        end
        if font
          config[:font] = font[params] rescue font
        end
        if justify
          config[:justify] = justify[params] rescue justify
        end
        if text
          config[:text] = text[params] rescue text
        end

        [TkcText, coords, config]
      end
    end
    
    # imageX,Y,key:val...
    #
    #  anchor anchorPos (center, n, nw, ...)
    #  image imageFileName
    #
    def image args, key_args
      anchor, image = key_args.values_at(*%w{anchor image})
      
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        xv, yv = args.map {|arg| arg[params] rescue arg}
        coords = [
          x + xv * cos_r - yv * sin_r,
          y + xv * sin_r + yv * cos_r
        ]
        
        config = {}
        if anchor
          config[:anchor] = anchor[params] rescue anchor
        end
        if image
          config[:image] = get_image(image[params]) rescue get_image(image)
        end

        [TkcImage, coords, config]
      end
    end
    
    def get_image file_name
      @@images ||= {}
      @@images[file_name] ||= TkPhotoImage.new(:file => file_name)
    end
    
    ## bitmap
    
    # anchor anchorPos
    # height pixels
    # width pixels
    # window pathName
##    def window args, key_args
##      x, y = args
##      
##    end

    # An embedded window that shows a list of key-value pairs.
##    def proplist args, key_args
##    end
    
    # just a very simple example!
    def polybox args, key_args
      dx, dy = args
      
      # return a proc to make the info needed to instantiate/update
      proc do |tkaroid, cos_r, sin_r|
        x = tkaroid.x
        y = tkaroid.y
        params = tkaroid.params

        ex = dx[params] rescue dx
        ey = dy[params] rescue dy

        points =
        [ [ ex,  ey],
          [ ex, -ey],
          [-ex, -ey],
          [-ex,  ey] ]

        coords = []
        points.each do |xv, yv|
          coords << x + xv * cos_r - yv * sin_r
          coords << y + xv * sin_r + yv * cos_r
        end

        ## possible to skip below if no changes?
        config = {}
        handle_generic_config(config, params, key_args)

        [TkcPolygon, coords, config]
      end
    end
  end
end

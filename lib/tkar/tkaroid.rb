module Tkar
  class Tkaroid
    attr_accessor :shape, :id, :flags, :layer, :x, :y, :r, :params
      # note r is in radians, unlike Tk
    attr_accessor :newly_added
    attr_reader :tag, :parts
    
    def initialize
      yield self if block_given?
      @tag = Tkaroid.tag(@id)
      @parts = []
    end

    def self.tag id
      "tkar#{id}"
    end
    
    def draggable?
      true ## get from flags
    end
    
    def drop_target?
      true ## get from flags
    end

    HOVER_COLOR   = 'SeaGreen1' ## user config
    DRAG_COLOR    = 'SeaGreen3' ## user config
    
    module CarefulColorize
      def colorize canvas, color
        parts = canvas.find_withtag(tag)
        parts.each do |part|
          case part
          when TkcImage
          else
            canvas.itemconfigure part, :fill => color
          end
        end
      end
    end

    # note: call after update, or else color is lost
    def colorize canvas, color
      canvas.itemconfigure tag, :fill => color
    rescue => ex
      if ex.message =~ /unknown option "-fill"/
        extend CarefulColorize
        colorize canvas, color
      else
        raise
      end
    end

    def drag_colorize canvas
      colorize canvas, DRAG_COLOR
    end

    def hover_colorize canvas
      colorize canvas, HOVER_COLOR
    end
    
    def decolorize canvas
      colorize canvas, nil
      update canvas
    end

    def update canvas, zoom=canvas.zoom
      tags = [tag]
      result = @newly_added
      
      if @newly_added
        @shape[self].each do |klass, coords, config|
          coords.map! {|x| x*zoom} if zoom
          coords << config
          part = klass.new(canvas, *coords)
          @parts << part
          part.raise tag rescue nil
          part.tags tags
        end
        @newly_added = false
        
      else
        i = 0
        @shape[self].each do |klass, coords, config|
          part = parts[i]; i += 1
          coords.map! {|x| x*zoom} if zoom
          part.coords(*coords)
          part.configure(config)
        end
      end
      
      return result
    end
  end
end

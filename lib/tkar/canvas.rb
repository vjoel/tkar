require 'tk'
require 'tkar/tkaroid'
require 'tkar/primitives'
require 'tkar/timer'

module Tkar
  class Canvas < TkCanvas
    class Error < Tkar::Error; end
    class MissingObject < Error; end
    
    attr_reader :zoom
    attr_accessor :follow_id
  
    def initialize(*)
      super

      @shapes = {}
      @shape_def = {}
      @zoom = 1.0
      init_objects
    end
    
    def init_objects
      @objects = {}
      @changed = {}
      @layers = []            # sorted array of layer numbers
      @objects_by_layer = {}  # layer => [obj, ...]
      follow nil
    end
    
    def zoom_by zf
      zf = Float(zf)
      @zoom *= zf
      
      vf = (1 - 1/zf) / 2
      
      x0, x1 = xview
      xf = x0 + vf * (x1-x0)

      y0, y1 = yview
      yf = y0 + vf * (y1-y0)

      scale 'all', 0, 0, zf, zf
      adjust_scrollregion

      xview "moveto", xf
      yview "moveto", yf
    end
    
    def adjust_scrollregion
      configure :scrollregion => @bounds.map {|u|u*@zoom}
      ## if all of canvas can be shown, hide the scroll bars
    end
    
    def xview(mode=nil, *args)
      if mode and mode == "scroll" and @follow_xdelta
        number, what = args
        x_pre, = xview
        r = super(mode, *args)
        x_post, = xview
        x0,y0,x1,y1 = @bounds
        @follow_xdelta += (x_post - x_pre) * (x1-x0)
        r
      elsif not mode
        super()
      else
        super(mode, *args)
      end
    end
    
    def yview(mode=nil, *args)
      if mode and mode == "scroll" and @follow_ydelta
        number, what = args
        y_pre, = yview
        r = super(mode, *args)
        y_post, = yview
        x0,y0,x1,y1 = @bounds
        @follow_ydelta += (y_post - y_pre) * (y1-y0)
        r
      elsif not mode
        super()
      else
        super(mode, *args)
      end
    end
    
    # fixes a bug in RubyTk
    def scan_dragto(x, y, gain = 10)
      tk_send_without_enc('scan', 'dragto', x, y, gain)
      self
    end

    def view_followed_obj
      tkaroid = get_object(@follow_id)
      if tkaroid
        view_at(tkaroid.x + @follow_xdelta, tkaroid.y + @follow_ydelta)
      end
    end

    def current_width
      Integer(TkWinfo.geometry(self)[/\d+/])
    end

    def current_height
      Integer(TkWinfo.geometry(self)[/\d+x(\d+)/, 1])
    end

    # ------------------------
    # :section: Tkaroid manipulation commands
    #
    # Methods which operate on the population of objects shown in the canvas.
    # ------------------------

    def get_shape name
      @shapes[name] || (fail MissingObject, "No such shape, #{name}")
    end
    
    def get_object tkar_id
      @objects[tkar_id] || (fail MissingObject, "No such object, #{tkar_id}")
    end
    
    def get_objects_by_layer layer
      ary = @objects_by_layer[layer]
      unless ary
        ary = @objects_by_layer[layer] = []
        @layers << layer
        @layers.sort!
      end
      ary
    end
    
    def insert_at_layer tkaroid
      layer = tkaroid.layer
      peers = get_objects_by_layer(layer)
      if peers.empty?
        high = @layers.find {|l| l > layer}
        if high
          high_objects = get_objects_by_layer(high)
          unless high_objects.empty?
            lower tkaroid.tag, high_objects.first.tag
          end
        else
          low = @layers.reverse.find {|l| l < layer}
          if low
            low_objects = get_objects_by_layer(low)
            unless low_objects.empty?
              raise tkaroid.tag, low_objects.last.tag
            end
          #else must be the only object!
          end
        end
      else
        raise tkaroid.tag, peers.last.tag
      end
      peers << tkaroid
    end
    
    def current_tkaroid
      object = find_withtag('current').first
      if object
        tags = object.tags
        tkar_id = tags.grep(/^tkar\d+$/).first[/\d+/].to_i
        @objects[tkar_id]
      end
    end
    
    # ------------------------
    # :section: Commands
    #
    # Methods which handle incoming commands.
    # ------------------------

    def add shape_name, tkar_id, flags, layer, x, y, r, *params
      del(tkar_id)
      
      tkaroid = Tkaroid.new do |t|
        t.shape   = get_shape(shape_name)
        t.id      = tkar_id
        t.flags   = flags
        t.layer   = layer
        t.x       = x
        t.y       = y
        t.r       = r
        t.params  = params
        t.newly_added = true
      end

      @objects[tkar_id] = tkaroid
      @changed[tkar_id] = tkaroid
    end

    # Not "delete"! That already exists in tk.
    def del tkar_id
      tkaroid = @objects[tkar_id]
      if tkaroid
        if @follow_id == tkar_id
          follow nil
        end
        delete tkaroid.tag
        @objects.delete tkar_id
        @changed.delete tkar_id
        get_objects_by_layer(tkaroid.layer).delete tkaroid
      end
    end

    def moveto tkar_id, x, y
      tkaroid = get_object(tkar_id)
      unless tkaroid.x == x and tkaroid.y == y
        tkaroid.x = x
        tkaroid.y = y
        @changed[tkar_id] = tkaroid
      end
    end

    def rot tkar_id, r
      tkaroid = get_object(tkar_id)
      unless tkaroid.r == r
        tkaroid.r = r
        @changed[tkar_id] = tkaroid
      end
    end

    def param tkar_id, idx, val
      tkaroid = get_object(tkar_id)
      params = tkaroid.params
      unless params[idx] == val
        tkaroid.params[idx] = val
        @changed[tkar_id] = tkaroid
      end
    end
    
    def check_param param
      if param.nil?
        nil
      elsif param.is_a? String and param[0] == ?*
        param_idx = Integer(param[1..-1])
        proc {|param_array| param_array[param_idx]}
      else
        (Integer(param) rescue Float(param)) rescue param
      end
    end
    
    def compile_shape defn
      part_spec_defs = defn.scan(/([_A-Za-z]+)([^;]*);?/)
      
      part_spec_defs.map do |prim_name, args|
        args = args.split(",")
        key_args, args = args.partition {|arg| /:/ =~ arg}

        macro = @shape_def[prim_name]
        if macro
          macro2 = macro.gsub(/\*\d+/) {|s| i=Integer(s[/\d+/]); args[i]}
          macro2 = [macro2, *key_args].join(",")
          compile_shape(macro2)
        else
          args.map! {|arg| check_param(arg)}
          key_args.map! {|key_arg| key_arg.split(":")}
          key_args.map! do |k, v|
            [Primitives.handle_shortcuts(k), v]
          end
          key_args = key_args.inject({}) {|h,(k,v)| h[k] = check_param(v); h}
          Primitives.send(prim_name, args, key_args)
        end
      end
    end

    def shape name, *defn
      defn = defn.join(";")
      part_spec_makers = compile_shape(defn)
      part_spec_makers.flatten!
      @shape_def[name] = defn # should prevent inf recursion
      
      @shapes[name] = proc do |tkaroid|
        cos_r = Math::cos(tkaroid.r)
        sin_r = Math::sin(tkaroid.r)
        
        part_spec_makers.map do |maker|
          maker[tkaroid, cos_r, sin_r]
        end
      end
    end

    def update
      z = (zoom - 1).abs > 0.01 && zoom
      
      thread = Thread.current
      pri = thread.priority
      thread.priority += 10
      
      @changed.each do |tkar_id, tkaroid|
        newly_added = tkaroid.update(self, z)
        if newly_added
          insert_at_layer(tkaroid)
        end
      end
      @changed.clear

      view_followed_obj if @follow_id
    ensure
      thread.priority = pri if thread
    end
    
    def title str
      @root.title str
    end
    
    #background, height, width # already defined!
    
    def window_xy x,y
      s = ""
      s << "+" if x > 0
      s << x.to_s
      s << "+" if y > 0
      s << y.to_s
      @root.geometry s
    end

    def zoom_to z
      zoom_by(z/@zoom)
    end
    
    def view_at x, y
      x0,y0,x1,y1 = @bounds
      width = TkWinfo.width(self)
      height = TkWinfo.height(self)
      xview "moveto", (x-x0-(width/(@zoom*2.0)))/(x1-x0).to_f
      yview "moveto", (y-y0-(height/(@zoom*2.0)))/(y1-y0).to_f
    end
    
    def view_at_screen x,y
      view_at(canvasx(x)/@zoom, canvasy(y)/@zoom)
    end

    def view_id id
      tkaroid = get_object(id)
      view_at tkaroid.x, tkaroid.y if tkaroid
    end
    
    def wait t
      unless @timer
        @timer = Timer.new(t)
      end
      @timer.wait(t)
    end
    
    def follow id
      @follow_id = id
      @follow_xdelta = id && 0
      @follow_ydelta = id && 0
    end
    
    def bounds x0,y0,x1,y1
      @bounds = [x0,y0,x1,y1]
      adjust_scrollregion
    end
    
    def delete_all
      @objects.values.each do |tkaroid|
        delete tkaroid.tag
      end
      init_objects
    end
    
    def scale_obj tkar_id, xf, yf
      tkaroid = get_object(tkar_id)
      z = @zoom
      scale tkaroid.tag, tkaroid.x*z, tkaroid.y*z, xf, yf
    end
  end
end

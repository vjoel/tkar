#!/usr/bin/env ruby

# based on the 24hr_clock example from the tkruby demos

# run like this: ruby dial.rb | tkar

# Do the housekeeping associated with each step in the animation
def draw s, delay = nil
  puts s # note if s is array, it is joined with "\n"
  if delay
    puts "wait #{delay}"
  end
  puts "update"
  $stdout.flush
end

# Output the shape def for a circle
def circle radius, foreground, background
  coords = [-radius, -radius, radius, radius]
  "oval#{coords.join(",")},fc:#{foreground},oc:#{background}"
end

# Output the shape def for a clock hand
def hand length, width, offset, color
  coords = [
    0, -offset,
    width, -offset-width,
    width, -length+width,
    0, -length,
    -width, -length+width,
    -width, -offset-width
  ]
  "poly#{coords.join(",")},fc:#{color},oc:#{color}"
end

def mark radius, length, width, color, font = nil, offset = nil, text = nil
  coords = [radius-length, 0, radius, 0]
  
  s = "line#{coords.join(",")},wi:#{width},fc:#{color}"
  
  if text
    s << " text#{radius+offset},0,anchor:center,justify:center,text:#{text}"
    s << ",fc:#{color},font:#{font}"
  end

  return s
end

def pie radius, extent, start, color
  "arc0,0,#{radius},#{radius},extent:#{extent},start:#{start},style:pieslice," +
    "fill:#{color}"
end

# Parameters for this drawing

size              = 200
radius            = size*0.9
cdot_size         = 5
cdot_color        = 'black'
hour_hand_color   = 'black'
minute_hand_color = 'gray25'
second_hand_color = 'gray50'
face_color        = "white"

mark_font     = "-*-Helvetica-Bold-R-Normal--*-100-*-*-*-*-*-*"
mark_width    = 3
mark_color    = 'black'
submark_color = 'gray50'

hour_hand_len   = 0.55*size
minute_hand_len = 0.85*size
second_hand_len = 0.88*size

hour_hand_width   = 1.8*cdot_size
minute_hand_width = 1.0*cdot_size
second_hand_width = 0.4*cdot_size

# Draw the shapes

draw %{

  # window setup
  
  title dial example
  background gray90
  width #{2*size + 20}
  height #{2*size + 20}
  zoom 1.0

  # shape definitions (most are not parametrized because they do not need
  # to change shape or color dynamically or have individual configuration
  # other than position and rotation)
  
  shape face #{circle(radius, face_color, "black")}

  shape cdot #{circle(cdot_size, cdot_color, cdot_color)}

  shape hour_hand #{
    hand(hour_hand_len, hour_hand_width, cdot_size*0.5, hour_hand_color)
  }

  shape minute_hand #{
    hand(minute_hand_len, minute_hand_width, cdot_size*0.5, minute_hand_color)
  }

  shape second_hand #{
    hand(second_hand_len, second_hand_width, cdot_size*0.5, second_hand_color)
  }
  
  shape mark #{
    mark(radius, radius*0.025, mark_width, submark_color)
  }
  
  # params: *0 is text
  shape labelled_mark #{
    mark(radius, radius*0.05, mark_width, mark_color,
         mark_font, radius*0.1, "*0")
  }
  
  # params: *0 is extent angle, *1 is start angle, *2 is color
  shape pie #{
    pie(radius, "*0", "*1", "*2")
  }

  # Add some objects
  
  #   shape         ID    flags   layer   x   y   rot   params...
  #--------------------------------------------------------------

  add face          1     -       10      0   0   0
  add cdot          2     -       20      0   0   0
  add hour_hand     3     -       15      0   0   0
  add minute_hand   4     -       16      0   0   0
  add second_hand   5     -       17      0   0   0
  add pie           6     -       12      0   0   0     15  75   red
  add pie           7     -       12      0   0   0     67 -72   green
  add pie           8     -       12      0   0   0     17 187   blue
}

draw %{
  # move the view to the right place to see object #1
  view_id 1
}

mark_strs = (0..11).map do |i|
  "add mark   #{100+i}     -       14      0   0  #{30*i+15}"
end

draw mark_strs

labelled_mark_strs = (0..11).map do |i|
  "add labelled_mark #{200+i}     -       14      0   0   #{30*i-90}   #{i*2}"
end

draw labelled_mark_strs

# Animate!

1_000_000.times do |i|
  h = i*0.001
  draw %{
    rot 3 #{h}
    rot 4 #{60*h}
    rot 5 #{60*60*h}
#    param 201 0 #{i}
#    param 8 0 #{i%100}
#    param 7 2 ##{s="%06x"%(i*32)}
  }
end

$stderr.puts "Press Enter to finish"
gets

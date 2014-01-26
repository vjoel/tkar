# An example based on a visualization tool for engineers
# developing in-vehicle safety systems.
#
# Run like:
#
# ruby <thisfile> | tkar
#
# Use ctrl-up and ctrl-down (or mouse wheel) to zoom in/out.
#
# Watch for the lead vehicle's brake lights to turn red.

def draw s
  puts s
#  puts "wait 0.04"
  puts "update"
  $stdout.flush
end

draw %{
  title Tavis-style animation using Tkar
  background gray90
  height 200
  width 1000
  zoom 2.5
  #bounds -100 0 3000 1000
  
  shape solid_line line0,*1,*0,*1,wi:0.1,fc:*2
  shape dash_line solid_line*0,*1,*2,da:48
  
  shape four_lanes solid_line*0,0,yellow solid_line*0,16,white \
    dash_line*0,4,white dash_line*0,8,white dash_line*0,12,white
  
  shape asphalt poly0,0,*0,0,*0,*1,0,*1,fc:0x807070
  
  # Typical usage:
  #
  # coneX,Y,R,THETA,-THETA/2,fc:COLOR,oc:COLOR
  #
  shape cone arc*0,*1,*2,*2,fc:yellow,oc:black,extent:*3,start:*4,style:pieslice
  
  shape radar cone0,0,150,15,-7.5,fc:gray,oc:red
  shape vision cone0,0,50,24,-12,fc:cyan,oc:red
  shape sensors vision radar
  shape target oval-1,-1,1,1,fc:red,oc:black

  shape carbox poly0,1.2,-5,1.2,-5,-1.2,0,-1.2,fc:red,oc:gray
  shape l_brake_light oval-5.2,-1.0,-5.0,-0.6,fc:*0,oc:*0
  shape r_brake_light oval-5.2,0.6,-5.0,1.0,fc:*0,oc:*0
  shape car carbox,fc:*0 l_brake_light*1 r_brake_light*1
  
  add asphalt    20 -   1  0  100  0 1000 16
  add four_lanes 21 -  10  0  100  0 1000

  add car         1 - 100  0  102  0 red  black
  add sensors     2 -   5  0  102  0
  add car         3 - 100 40  102  0 blue black
  
  add target     10 - 110 35  102  0
  
  follow 1
}

if true
  (0..600).each do |i|
    j = i+40
    dx = rand*4 - 2
    dy = rand*4 - 2
    draw %{
      move 1 #{i} 102
      #{
      if i == 200
        "param 3 1 red"
      elsif i == 300
        "param 3 1 black"
      end
      }
      move 2 #{i} 102

      move 3 #{j} 102

      move 10 #{j-5+dx} #{102+dy}
    }
  end
end

puts "done"
$stdout.flush

$stderr.puts "Press enter to finish."
gets

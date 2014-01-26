#!/usr/bin/env ruby

# A sample of many of the TkCanvas features usable in tkar.
#
# Run like:
#
#  ruby sample.rb | tkar
#
# Not that if you click and drag on things, you can see the commands in the
# stdout. If your program is listening to that stream, it can feedback into
# the animation.

puts %{
title Strange bits of stuff: Tkar demo
background gray95
height 600
width 600

shape box polybox50,50,fc:*1,oc:*0  polybox5,5,fc:*0,oc:*1  \
oval30,-30,60,-60,fc:white,oc:gray

shape box2 polybox10,10,fc:*0,oc:*1

shape cone arc*0,*1,*2,*2,fc:yellow,oc:black,extent:30,start:-15,style:pieslice

shape thang polybox40,60,fc:*0,oc:*1,wi:5 \
 polybox*2,10,fc:*1,oc:red,da:48,wi:3 \
 cone20,40,60 \
 line20,40,80,40,fc:purple,da:44

shape radar \
 cone0,0,*0 \
 cone20,0,*0,style:chord \
 cone40,0,*0,style:chord \
 line0,0,-20,-20,*1,0,*1,*1,0,-60,arrow:last,arrowshape:10+8+6,\
smooth:true,wi:2,fc:0x609000

shape blob \
 poly0,0,10,0,20,5,15,30,-3,6,-20,40,-15,-10,5,5,smooth:true,oc:red,fc:0 \
 text0,50,anchor:c,justify:center,width:40,text:*0,fc:0 \
 image25,50,anchor:c,image:home.gif

add box 3 - 4 210 210 0 0xff0000 0x00ff00
add box2 4 - 4 300 210 0 0x0000ff 0x00ff00
update
}

$stdout.flush; sleep 1

puts %{
del 4
update
}

$stdout.flush; sleep 1

puts %{
move 3 165 150
param 3 0 0xffffff
param 3 1 blue
add box2 1 - 2 280 220 25 orange cyan
add thang 2 - 3 200 200 45 magenta green 80
add radar 6 - 5 360 360 25 60 -40
add blob 7 - 6 140 280 0
param 7 0 This is some text
update
}

$stdout.flush; sleep 1

45.step(3600,5) do |i|
  xy = 200 + i/15.0
  puts %{
  rot 2 #{i}
  move 2 #{xy} #{xy}
  param 2 2 #{80-(i/30.0)}
  rot 1 #{-i}
  param 6 0 #{60+i%40}
  param 6 1 #{-20-i%80}
  update
  }
  $stdout.flush; #sleep 0.02
end

500.times do |i|
  puts %{
  scale 3 #{1.0 + 0.005 * Math::sin(i/100.0)} 1.0
  update
  }
end

$stdout.flush; sleep 1

puts "done"
$stdout.flush

$stderr.puts "Press enter to finish."
gets

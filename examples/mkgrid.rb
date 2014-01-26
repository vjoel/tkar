# mkgrid -- generate grid code for a tkar shape file
#
# To see what the grid looks like by itself:
#
#   ruby mkgrid.rb | tkar --radians --persist
#
# (The --radians is because this is designed to be used from
# code that uses radians for angles. The --persist is because
# this is just some static objects, not an animation, so it will
# close after drawing without the persist option.)
#
# To use with other code, run like this:
#
#   ruby mkgrid > grid.shp
#
# Then, add a line like this to your shape file:
#
#   load grid.shp
#
# It doesn't really matter what part of the file you put the line in.
# Near the top is ok.
#
# Make sure grid.shp is in the same dir as the shape file, or enter the
# relative path.
#
# Adjust the parameters as needed: xmin, interval, mark_font, etc.
#
# You can disable the grid by commenting the "load grid.shp" line in
# the shape file (insert a # character at the beginning of the line)
#
# Note: if you are using this without simulink, remember to use the --radians
# option to tkar, otherwise it will look funny!

mark_font = "-*-Helvetica-Bold-R-Normal--*-90-*-*-*-*-*-*"

puts "shape grid_line line0,0,*0,0,wi:0.1,fc:black"
puts "shape mark text0,0,anchor:sw,justify:center,text:*0,fc:red,font:#{mark_font}"
puts

id = 12000 # high enough not to interfere (hacky!)
r = Math::PI/2 # when called from the tkar simulink block, tkar uses radians

xmin = -2000; xmax = 2000; xmid = 0
ymin = -2000; ymax = 2000; ymid = 0
interval = 100

xlen = xmax - xmin
ylen = ymax - ymin

(xmin..xmax).step(interval) do |x|
    puts "add grid_line #{id+=1} - 0 #{x} #{ymin} #{r} #{ylen}"
    puts "add mark      #{id+=1} - 0 #{x} #{ymid} 0    #{x}"
end

(ymin..ymax).step(interval) do |y|
    puts "add grid_line #{id+=1} - 0 #{xmin} #{y} 0 #{xlen}"
    puts "add mark      #{id+=1} - 0 #{xmid} #{y} 0 #{y}"
end

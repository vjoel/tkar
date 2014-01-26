# Visualization of cpu usage from ps output. Run like this:
#
# ruby ps.rb | tkar
#
# If you don't see the pids, scroll down.

$stdout.sync = true

puts %{
title Process Status
height 600
width 600
bg white
update

shape bar \
  poly0,0,50,0,50,*0,0,*0,oc:black,width:2,fc:*2 \
  text25,20,anchor:c,justify:center,width:50,text:*1,fc:black

#     SHAPE_NAME      ID  FLAGS   LAYER     X     Y    R  PARAMS...
add   bar             1      -     100     50   550    0  0 unknown blue
add   bar             2      -     100    150   550    0  0 unknown blue
add   bar             3      -     100    250   550    0  0 unknown blue
add   bar             4      -     100    350   550    0  0 unknown blue
add   bar             5      -     100    450   550    0  0 unknown blue
update
}

PS_FIELDS   = "pcpu,pmem,s,time,pid,cmd"
TOP_CPU_CMD = "ps -A --sort=-pcpu -o cputime,#{PS_FIELDS} | head -n 6"

loop do
  s = `#{TOP_CPU_CMD}`
  a = s.map {|l| l[/[0-9:]*\s+(\S+)/, 1]}.map {|t| Float(t) rescue nil}.compact
  b = s.map {|l| l[30,5]}.map {|t| Integer(t) rescue nil}.compact
  i = 1
  a.zip(b) do |pcpu, pid|
    puts "param #{i} 1 #{pid}"
    puts "param #{i} 0 -#{pcpu*5}"
    i += 1
    $stderr.puts [pcpu, pid].inspect
  end
  puts "update"
  
  sleep 1
end


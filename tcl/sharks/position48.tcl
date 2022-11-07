set z -60

set id 0
for {} {$id < [expr $opt(nn)/4]} {incr id}  {
  $position($id) setX_  [expr $id*80]
  $position($id) setY_  660
  $position($id) setZ_ $z
}
set x_max [expr $id*80]
for {} {$id < $opt(nn)/2} {incr id}  {
  $position($id) setX_  [expr $id*80 + 40 - $x_max]
  $position($id) setY_  590
  $position($id) setZ_ $z
}

for {} {$id < [expr 3*$opt(nn)/4]} {incr id}  {
  $position($id) setX_  [expr $id*80 - $x_max*2]
  $position($id) setY_  520
  $position($id) setZ_ $z
}

for {} {$id < $opt(nn)} {incr id}  {
  $position($id) setX_  [expr $id*80 + 40 - $x_max*3]
  $position($id) setY_  450
  $position($id) setZ_ $z
}

for {set id 0} {$id < $opt(nn)} {incr id}  {
  set x [$position($id) getX_]
  puts "position($id) = $x"
}

set opt(waypoint_file)  "shark_path.csv"

$shark_position setX_ 650 
$shark_position setY_ 1000 
$shark_position setZ_ -21

set fp [open $opt(waypoint_file) r]
set file_data [read $fp]
set data [split $file_data "\n"]
foreach line $data {
	if {[regexp {^(.*),(.*),(.*),(.*),(.*)$} $line -> t x y z s]} {
		puts "NEW POSITION $t $x $y $z $s"
		$ns at $t "$shark_position update"
		$ns at $t "$shark_position setdest $x $y $z $s"
    }
}
#$ns at $opt(starttime) "$shark_position setdest 50 100 -10 1"
#$ns at 100 "$shark_position setdest 1000 100 -10 10"
#$ns at 200 "$shark_position setdest 500 10 -10 1"
#$ns at 300 "$shark_position setdest 50 -10 -10 1"
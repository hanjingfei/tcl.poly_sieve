#!/usr/bin/tclsh8.6
source ./procs.tcl
set DEBUG           0

proc galois_add {x y} {
    set order_x [llength $x]
    set order_y [llength $y]
    if {$order_x == $order_y} {
        set order_z $order_x
    } elseif {$order_x > $order_y} {
        set order_z $order_x
        set y [concat [lrepeat [expr {$order_z - $order_y}] 0] $y]
    } else {
        set order_z $order_y
        set x [concat [lrepeat [expr {$order_z - $order_x}] 0] $x]
    }
    #printvar order_z
    #printvar x
    #printvar y
    set z [lrepeat $order_z 1]
    #printvar z
    for {set i 0} {$i < $order_z} {incr i} {
        if {[lindex $x $i] == [lindex $y $i]} {
            set z [lreplace $z $i $i 0]
        }
        #printvar i
        #printvar z
    }
    return $z
}

proc galois_mul {x y} {
    set order_x [llength $x]
    set order_y [llength $y]
    set order_z [expr {$order_x + $order_y}]
    set z [lrepeat $order_z 0]
    for {set i [expr {$order_x - 1}]} {$i >= 0} {incr i -1} {
        if {[lindex $x $i] == 1} {
            set z [galois_add $z $y]
        }
        set y [linsert $y end 0]
    }
    return $z
}

#set x   {1 0 0}
#set x   {0 1 0}
#set x   {0 0 1}
#set x   {0 1 1}
#set y {1 1 1 1}
set x   {0 1 0}
set y {1 0 1 1}
set z   {1 1 0}
#puts "galois_add($x, $y) = [galois_add $x $y]"
#puts "galois_mul($x, $y) = [galois_mul $x $y]"

#x^4 = (x^3 + x + 1) * (x) + (x^2 + x)
#puts "[galois_add [galois_mul $x $y] $z]"

proc find_order {x} {
    set order [llength $x]
    set order_z 0
    for {set i 0} {$i < $order} {incr i} {
        if {[lindex $x $i] == 1} {
            set order_z [expr {$order - $i - 1}]
            return $order_z
        }
    }
}
#puts "[find_order $y]"

proc int2poly {int n} {
    set fmt_str "\%0${n}b"
    #printvar fmt_str
    set bin [format $fmt_str $int]
    for {set i 0} {$i < $n} {incr i} {
        lappend poly [string index $bin $i]   
    }
    return $poly
}
#puts [int2poly 7 5]

proc poly2int {poly} {
    set int 0
    set n [llength $poly]
    for {set i 0} {$i < $n} {incr i} {
        set int [expr {$int + ([lindex $poly $i] * (2**($n - $i - 1)))}]
    }
    return $int
}
#puts [poly2int {1 0 0 1 1}]

#finding reduction polynomial
#order is N-1
set N 9
set max [expr {2**${N}}]
set poly_list [lrepeat $max 1]
#0, 1
set poly_list [lreplace $poly_list 0 1 0 0]

set start_us [clock microseconds]
#method 1
for {set i 2} {$i < $max} {incr i} {
    set i_poly [int2poly $i $N]
    set i_order [find_order $i_poly]
    #round: x*(x+1), x*x**2,
    for {set p $i} {$p < $max} {incr p} {
        set p_poly [int2poly $p $N]
        set p_order [find_order $p_poly]
        if {[expr {$i_order + $p_order}] > [expr {$N - 1}]} {
            break
        }
        set poly_prod [galois_mul $p_poly $i_poly]
        set p_next [poly2int $poly_prod]
        set poly_list [lreplace $poly_list $p_next $p_next 0]
        printvar i_poly
        printvar p_poly
        printvar poly_prod
        printvar p_next
    }
    printvar i
    printvar poly_list
}
set end_us [clock microseconds]
set time_us [expr {$end_us - $start_us}]

set put_str ""
set j_num 0
set j_index 0
foreach j $poly_list {
    if {$j} {
        append put_str "[format "%08d" $j_index] : [int2poly $j_index $N]\n"
        incr j_num
    }
    incr j_index
}
puts $put_str
puts "$time_us us"


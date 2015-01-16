# Common TCL functions for use by any schema file
#include(Copyright)
package require wylib

# Short-hand for subst
#------------------------------------------
proc s {args} {uplevel subst $args}

# Turn a TCL list into a comma-separated list
#----------------------------------------------------------------
proc fld_list {items {alias {}}} {
    if {$alias == {}} {
        return [join $items {, }]
    } else {
        return "$alias.[join $items ", $alias."]"
    }
}

# Turn each field into "fld=new.fld" and return comma separated list
#----------------------------------------------------------------
proc fld_list_eq {items {app new} {delim {, }} {ffields {}}} {
    if {$ffields != {}} {array set ff $ffields}
    set rlist {}
    foreach item $items {
        if {![info exists ff($item)]} {
            lappend rlist "$item = $app.$item"
        } else {
            lappend rlist "$item = $ff($item)"
        }
    }
    return [join $rlist $delim]
}

# Generate the values for an insert statement
#----------------------------------------------------------------
proc ins_list {fields {ffields {}} {delim {, }}} {
    if {$ffields != {}} {array set ff $ffields}
    set fvals {}
    foreach f $fields {			;#load up value fields
        if {![info exists ff($f)]} {
            lappend fvals "new.$f"	;#either the default: new.field
        } else {
            lappend fvals $ff($f)	;#or a forced value
        }
    }
    foreach {col val} $ffields {	;#any columns in force list not in original field list?
        if {![lcontain $fields $col]} {error "Forced field $col not contained in original field list: $fields"}
    }
    return [join $fvals $delim]
}

# Generic view insert rule
#----------------------------------------------------------------
proc rule_insert {view table fields {where {}} {ffields {}}} {
    if {$ffields != {}} {array set ff $ffields}
    foreach f $fields {			;#load up value fields
        if {![info exists ff($f)]} {
            lappend fvals "new.$f"	;#either the default: new.field
        } else {
            lappend fvals $ff($f)	;#or a forced value
        }
    }
    foreach {col val} $ffields {	;#any columns in force list not in original field list?
        if {![lcontain $fields $col]} {
            lappend fields $col
            lappend fvals "$val"
        }
    }
    if {$where != {}} {set rval "create rule [translit . _ $view]_innull as on insert to $view do instead nothing;\n    "}
    append rval "create rule [translit . _ $view]_insert as on insert to $view\n"
    if {$where != {}} {append rval "        $where" "\n"}
    append rval "        do instead insert into $table ([fld_list $fields]) values ([join $fvals {, }])"
    return $rval
}

# Create the list of fields for an update statement with certain field possibly with forced values
#----------------------------------------------------------------
proc upd_list {upfields {ffields {}} {delim {, }}} {
    if {$ffields != {}} {array set ff $ffields}
    set fvals {}
    foreach f $upfields {			;#load update fields
        if {![info exists ff($f)]} {
            lappend fvals "$f = new.$f"		;#either the default: field = old.field
        } else {
            lappend fvals "$f = $ff($f)"	;#or a forced value
        }
    }
    foreach {col val} $ffields {		;#any columns in force list not in original field list?
        if {![lcontain $upfields $col]} {
            lappend fvals "$col = $val"
        }
    }
    return [join $fvals $delim]
}

# Generic view update rule
#----------------------------------------------------------------
proc rule_update {view table upfields pkfields {where {}} {ffields {}} {sfx {}}} {
    if {$ffields != {}} {array set ff $ffields}
    foreach f $upfields {			;#load update fields
        if {![info exists ff($f)]} {
            lappend fvals "$f = new.$f"		;#either the default: field = old.field
        } else {
            lappend fvals "$f = $ff($f)"	;#or a forced value
        }
    }
    foreach {col val} $ffields {		;#any columns in force list not in original field list?
        if {![lcontain $upfields $col]} {
            lappend fvals "$col = $val"
        }
    }

    if {$where != {} && $sfx == {}} {set rval "create rule [translit . _ $view]_upnull as on update to $view do instead nothing;\n    "}
    append rval "create rule [translit . _ $view]_update$sfx as on update to $view\n"
    if {$where != {}} {append rval "        $where" "\n"}
    append rval "        do instead update $table set [join $fvals {, }] where [fld_list_eq $pkfields old { and }]"
    return $rval
}

# Generic view delete rule
#----------------------------------------------------------------
proc rule_delete {view table pkfields {where {}} {sfx {}}} {
    if {$where != {} && $sfx == {}} {set rval "create rule [translit . _ $view]_denull as on delete to $view do instead nothing;\n    "}
    append rval "create rule [translit . _ $view]_delete$sfx as on delete to $view\n"
    if {$where != {}} {append rval "        $where" "\n"}
    append rval "        do instead delete from $table where [fld_list_eq $pkfields old { and }]"
    return $rval
}

# Create a trigger function and its associated trigger
#----------------------------------------------------------------
proc trigfunc {table suffix deps befaft pre body} {
    set funcname "${table}_tf_${suffix}()"
    function $funcname "$deps" "returns trigger $pre language plpgsql as \$\$\n$body\n\$\$;"
    set trigname "${table}_tr_$suffix"
    trigger $trigname {} "$befaft on $table for each row execute procedure $funcname"
}

# Create a clause showing if none of the fields have changed from old to new on an upate
#----------------------------------------------------------------
proc samelist {args} {
    set flist {}
    foreach f $args {
        lappend flist "(new.$f is not distinct from old.$f)"
    }
    if {[llength $flist] > 1} {
        return "([join $flist { and }])"
    } else {
        return "([join $flist { and }])"
    }
}

# Create a clause showing if any/all of the fields have a null value
#----------------------------------------------------------------
proc null_list {list {prefix new} {cond or} {not {}}} {
    if {[string range $prefix end end] != {.}} {append prefix {.}}
    set flist {}
    foreach f $list {
        lappend flist "($prefix$f is $not null)"
    }
    if {[llength $flist] > 1} {
        return "([join $flist " $cond "])"
    } else {
        return "[join $flist " $cond "]"
    }
}

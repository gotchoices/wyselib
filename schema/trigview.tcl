#Create triggers to allow to insert/update/delete on a view
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------

namespace eval trigview {
    set dquery1 {'select string_agg(val,'','') from wm.column_def where obj = $1;'}	;#query to fetch default field assignments
    set dquery2 {'select ' || str || ';'}		;#query to perform default field assignments
}

# Create the field and values list for an insert rule: (f1, f2, ... fn) values (new.v1, new.v2, ... new.vn)
#----------------------------------------------------------------
proc trigview::infields {fields ffields {rec new} {key1 {}} {key2 {}} {kalias new}} {
    if {$ffields != {}} {array set ff $ffields}
#puts "list_infields: fields:$fields ffields:$ffields"
    set i 0; foreach col $key1 {	;#add in some optional forced key values
        set k2f [lindex $key2 $i]
        if {$k2f == {}} {set k2f $col}
        set ff($col) "$kalias.$k2f"
        incr i
    }
    set fvals {}
    foreach f $fields {			;#load up value fields
        if {[info exists ff($f)]} {	;#if there is a forced value given
            lappend fvals $ff($f)	;#use it
        } else {
            lappend fvals "$rec.$f"	;#else the default: record.field
        }
    }
    foreach {col val} $ffields {	;#include columns in force list but not in original field list
        if {![lcontain $fields $col]} {
            lappend fields $col
            lappend fvals "$val"
        }
    }
    return [list ([join $fields ,]) values ([join $fvals ,])]
}

# Create the field list for an update rule: f1=new.v1, f2=new.v2, ... fn=new.vn
#----------------------------------------------------------------
proc trigview::upfields {fields ffields {rec new}} {
    if {$ffields != {}} {array set ff $ffields}
    set fvals {}
    foreach f $fields {
        if {[info exists ff($f)]} {		;#if a forced field given
            lappend fvals "$f = $ff($f)"	;#use it
        } else {
            lappend fvals "$f = $rec.$f"	;#else the default: field = record.field
        }
    }
    foreach {col val} $ffields {		;#any columns in force list not in original field list?
        if {![lcontain $fields $col]} {
            lappend fvals "$col = $val"
        }
    }
    return [join $fvals ,]
}

#Template for generic insert trigger function
#----------------------------------------------------------------
set trigview::insfunc {
  returns trigger language plpgsql security definer as \$\$
  declare
    ${ndef}trec record;					-- temporary record for single table
    str  varchar;					-- command string
  begin
    ${precall}execute $trigview::dquery1 into str using '$view';	-- get default field assignments from data dictionary
    execute $trigview::dquery2 into trec using new;	-- force nulls to defaults, where appropriate
    insert into $table [infields $fields $ffields trec $keyfield] returning [join $keyfield ,] into [fld_list $keyfield new];
    select into new * from $view where [fld_list_eq $keyfield new { and }];	-- Fill new with any auto-populated values
    ${postcall}return new;
  end;
\$\$}

# Insert on a view, implemented as a view trigger firing instead of the insert
#    fields:	columns to insert in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to force to a specified value
#----------------------------------------------------------------
proc trigview::insert {view table fields keyfield {ffields {}} {postfunc {}} {prefunc {}}} {
#puts "\nfunction ${view}_insfunc() $view $func"
    if {$prefunc != {}} {
      set precall "nrec = new; new = ${prefunc}(nrec, null, TG_OP); if new is null then return null; end if;\n    "
    } else {set precall {}}
    if {$postfunc != {}} {
      set postcall "nrec = new; new = ${postfunc}(nrec, null, TG_OP);\n    "
    } else {set postcall {}}
    if {$precall != {} || $postcall != {}} {
      set ndef "nrec ${view};\n    "
    } else {set ndef {}}
    set func [subst $trigview::insfunc]			;#evaluate function template
    function "${view}_insfunc()" $view $func

    trigger [translit . _ $view]_tr_ins [list ${view}_insfunc()] "instead of insert on $view for each row execute procedure ${view}_insfunc();"
    return {}
}

#Template for generic update trigger function
#----------------------------------------------------------------
set trigview::updfunc {
  returns trigger language plpgsql security definer as \$\$
  ${ndef}begin
    ${precall}update $table set [upfields $fields $ffields] where [fld_list_eq $keyfield old { and }] returning [join $keyfield ,] into [fld_list $keyfield new];
    select into new * from $view where [fld_list_eq $keyfield new { and }];	-- Fill new with any auto-populated values
    ${postcall}return new;
  end;
\$\$}

# Update a view, using a trigger function
#    fields:	columns to update in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to receive a forced value on each update
#----------------------------------------------------------------
proc trigview::update {view table fields keyfield {ffields {}} {postfunc {}} {prefunc {}}} {
    set precall {}; if {$prefunc != {}} {
      set precall "nrec = new; orec = old; new = ${prefunc}(nrec, orec, TG_OP); if new is null then return null; end if;\n    "
    }
    set postcall {}; if {$postfunc != {}} {
      set postcall "nrec = new; orec = old; new = ${postfunc}(nrec, orec, TG_OP);\n    "
    }
    if {$precall != {} || $postcall != {}} {
      set ndef "declare\n    nrec ${view}; orec ${view};\n  "
    } else {set ndef {}}
    set func [subst $trigview::updfunc]		;#evaluate function template
#puts "\nfunction ${view}_updfunc() $view $func"
    function "${view}_updfunc()" $view $func

    trigger [translit . _ $view]_tr_upd [list ${view}_updfunc()] "instead of update on $view for each row execute procedure ${view}_updfunc();"
    return {}
}

# Delete from view, using a trigger
# Just implement this with the rule macro--no trigger version needed for now
#----------------------------------------------------------------
#proc trigview::delete {view tabrecs} {
#}

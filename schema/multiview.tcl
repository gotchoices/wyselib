#Create triggers to allow to insert/update/delete multiple tables joined together into a single view
#This is an improvement on multirule, better handling in view triggers
#Copyright WyattERP.org; See license in root of this package
#TODO:
#- Test postfunc on update function
#- 
#----------------------------------------------------------------
# Is this chart still accurate with view trigger implementation?
# If record exists in:		and:		do:
# ent	link	empl		issue_cmd	update		insert
#
# no	no	no		insert		-		ent,link,empl
# yes	no	no		insert		ent		link,empl
# yes	yes	no		insert		-		- (will crash PK in ent_link)
# yes	yes	yes		insert		-		- (will crash PK in ent_link)
#
# no	no	no		update		-		- (no PK in ent to reference)
# yes	no	no		update		ent		link,empl
# yes	yes	no		update		ent,link	empl
# yes	yes	yes		update		ent,link,empl	-

namespace eval multiview {
    set dquery1 {'select string_agg(val,'','') from wm.column_def where obj = $1 and not col ~ $2;'}	;#query to fetch default field assignments
    set dquery2 {'select ' || str || ';'}		;#query to perform default field assignments
}

# Create the field and values list for an insert rule: (f1, f2, ... fn) values (new.v1, new.v2, ... new.vn)
#----------------------------------------------------------------
proc multiview::infields {fields ffields {rec new} {key1 {}} {key2 {}} {kalias new}} {
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
proc multiview::upfields {fields ffields {rec new}} {
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
set multiview::insfunc {
  returns trigger language plpgsql security definer as \$\$
  declare
    trec record;					-- temporary record for single table
    nrec ${view};					-- record in native type of view
    str  varchar;					-- temporary string
  begin
    if exists (select [join $keyfield ,] from $table where [fld_list_eq $keyfield new { and }]) then	-- if primary table record already exists
        $uquery;					-- an update query, if any specified
    else
        execute $multiview::dquery1 into str using '$table','^_';	-- get default field assignments from data dictionary
-- raise notice 'ts:%', str;
        execute $multiview::dquery2 into trec using new;	-- force nulls to defaults, where appropriate
        insert into $table [infields $fields $ffields trec] returning [join $keyfield ,] into [fld_list $keyfield new];
    end if;
    
    [join $ilist "\n    "]    	-- insert queries for subordinate tables
    select into new * from $view where [fld_list_eq $keyfield new { and }];	-- Fill new with any auto-populated values
    $postcheck
    return new;
  end;
\$\$}

# Insert on multiple joined tables with an auto generated key (alternate implementation)
# This is implemented as a view trigger firing instead of the insert
# This does not return sql--it creates wyseman objects directly
# Table Record: {table_name {fields to insert} primary_key {fields with forced values}
#    fields:	columns to insert, if necessary in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to force to a specified value
# Postfunc: A function to call before declaring success; returns boolean
#----------------------------------------------------------------
proc multiview::insert {view tabrecs {postfunc {}}} {
    set rcnt 0						;#iterates through each table record
    set lrec [expr [llength $tabrecs] - 1]		;#last record of the list
    set ilist {}					;#subordinate table insert accumulator
    foreach tabrec $tabrecs {				;#for each table
        lassign $tabrec table fields keyfield ffields
#puts "Table:$table fields:$fields\nKeyfield:$keyfield ffields:$ffields"
        if {$rcnt == 0} {				;#on the first table record
            if {$ffields != {}} {
                set uquery "update $table set [upfields {} $ffields] where [fld_list_eq $keyfield new { and }]"
            } else {
                set uquery {null}
            }
            set tab0 [list $table $fields $keyfield $ffields]	;#save first table record for later
            set keyfield0 $keyfield
        } elseif {$rcnt <= $lrec} {			;#do for remaining records
            lappend ilist "execute $multiview::dquery1 into str using '$table','^_';"
            lappend ilist "execute $multiview::dquery2 into trec using new;"
            lappend ilist "insert into $table [infields $fields $ffields trec $keyfield $keyfield0 new];"
        }
        incr rcnt
    }
    lassign $tab0 table fields keyfield ffields		;#come back to first table record
    set postcheck {}; if {$postfunc != {}} {
      set postcheck "nrec = new; new = ${postfunc}(nrec, null, TG_OP);"
    }
    set func [subst $multiview::insfunc]		;#evaluate function template in that context
#puts "\nfunction ${view}_insfunc() $view $func"
    function "${view}_insfunc()" $view $func

    trigger [translit . _ $view]_tr_ins [list ${view}_insfunc()] "instead of insert on $view for each row execute procedure ${view}_insfunc();"
    return {}
}

#Template for generic update trigger function
#----------------------------------------------------------------
set multiview::updfunc {
  returns trigger language plpgsql security definer as \$\$
  declare
    trec record;		-- temporary record for single table
    nrec ${view}; orec ${view};	-- records in native type of view
    str  varchar;		-- temporary string
  begin
    $uquery;			-- Do unconditional update on the primary table
    
    [join $qlist "\n    "]    	-- insert queries for subordinate tables
    select into new * from $view where [fld_list_eq $keyfield0 new { and }];	-- Fill new with any auto-populated values
    $postcheck
    return new;
  end;
\$\$}

set multiview::updblock {
    if exists (select [join $keyfield ,] from $table where [fld_list_eq $keyfield old { and }]) then				-- if primary table record already exists
        update $table set [upfields $fields $ffields] where [fld_list_eq $keyfield old { and }];
    else
        execute $multiview::dquery1 into str using '$table','^_';	-- get default field assignments from data dictionary
-- raise notice 'ts:%', str;
        execute $multiview::dquery2 into trec using new;	-- force nulls to defaults, where appropriate
        insert into $table [infields $fields $ffields trec $keyfield $keyfield0];
    end if;
}

# Update on multiple joined tables, implemented with view trigger
# Handle separately each table needing an update
# Produce an additional insert in the case where a record doesn't exist yet
#    fields:	columns to update in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to receive a forced value on each update
#----------------------------------------------------------------
proc multiview::update {view tabrecs {postfunc {}}} {
    set rcnt 0
    set qlist {}
    foreach tabrec $tabrecs {
        lassign $tabrec table fields keyfield ffields
#puts "Table:$table fields:$fields keyfield:$keyfield ffields:$ffields"
        if {$rcnt == 0} {
            set keyfield0 $keyfield
            set uquery "update $table set [upfields $fields $ffields] where [fld_list_eq $keyfield old { and }] returning [join $keyfield ,] into [fld_list $keyfield new]"
        } else {
            lappend qlist [subst $multiview::updblock]
        }
        incr rcnt
    }

    set postcheck {}; if {$postfunc != {}} {
      set postcheck "nrec = new; orec = old; new = ${postfunc}(nrec, orec, TG_OP);"
    }
    set func [subst $multiview::updfunc]		;#evaluate function template
#puts "\nfunction ${view}_updfunc() $view $func"
    function "${view}_updfunc()" $view $func

    trigger [translit . _ $view]_tr_upd [list ${view}_updfunc()] "instead of update on $view for each row execute procedure ${view}_updfunc();"
    return {}
}

# Delete from view with multiple joined tables
# Just implement this with a rule--no trigger needed for now
#----------------------------------------------------------------
proc multiview::delete {view tabrecs} {
    set rcnt 1
    set lrec [expr [llength $tabrecs] - 1]	;#last record we will consider
    set sql {}
    foreach tabrec $tabrecs {
        lassign $tabrec table keyfield where
#puts "Table:$table keyfield:$keyfield where:$where"
        if {$rcnt == 1 && $where != {}} {
            append sql "create rule [translit . _ $view]_delete_0 as on delete to $view do instead nothing;\n    "
        }
#puts " rcnt:$rcnt lrec:$lrec"
        if {$rcnt == 1 || $rcnt >= $lrec} {set ai {instead}} else {set ai {also}}
        append sql "create rule [translit . _ $view]_delete_$rcnt as on delete to $view "
        if {$where != {}} {append sql "where $where" " "}
        append sql "do $ai delete from $table where [fld_list_eq $keyfield old { and }];\n    "
        incr rcnt
    }
    return $sql
}

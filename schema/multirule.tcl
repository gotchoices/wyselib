#Create rules to allow to insert/update/delete multiple tables joined together into a single view
#This uses primarily rules, but suffers from the defect that it can't handle a "returning" clause.
#It is superceded by multiview.tcl which uses view triggers.
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------
# Used, for example with empl.empl_v to insert/update records
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

# Create the field and values list for an insert rule: (f1, f2, ... fn) values (new.v1, new.v2, ... new.vn)
#----------------------------------------------------------------
proc rule_infields {fields ffields} {
    if {$ffields != {}} {array set ff $ffields}
#puts "rule_infields: fields:$fields ffields:$ffields"
    foreach f $fields {			;#load up value fields
        if {[info exists ff($f)]} {	;#if there is a forced value given
            lappend fvals $ff($f)	;#use it
        } else {
            lappend fvals "new.$f"	;#else the default: new.field
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

# Insert on multiple joined tables with an auto generated key (Caution: can't do "returning")
# The first given table will be inserted within a called function to generate the key
# Subsequent tables (except the last one) will also be inserted in the function
# The last table will be inserted in the rule using the key on a single field (so the operation will properly return an insert status)
# Unlike some other rule macros, this does not return sql--it creates wyseman objects directly
# Table Record: {table_name {fields to insert} primary_key {fields with forced values}
#----------------------------------------------------------------
proc rule_inmulta {view tabrecs} {
    set rcnt 0
    set lrec [expr [llength $tabrecs] - 1]		;#last record we will consider
    set kflist {}					;#list of fields to find primary key in
    foreach tabrec $tabrecs {				;#for each table
        lassign $tabrec table fields keyfield ffields
#puts "table:$table fields:$fields\n  keyfield:$keyfield ffields:$ffields"
        if {[llength $keyfield] > 1} {lassign $keyfield keyfield keytype} else {set keytype {int}}	;#can specify type of primary key if not integer
        if {$rcnt == 0} {				;#only do for first record
            set    body "if exists (select * from $table where $keyfield = rid) then\n"
            append body "        update $table set [rule_upfields {} $ffields] where [fld_list_eq $keyfield new { and }];\n\n"
            append body "    else\n"
            append body "        insert into $table [rule_infields $fields $ffields] returning into rid $keyfield;\n"
            append body "    end if;\n"
            set fkeyfield $keyfield
            set fkeytype $keytype
        } elseif {$rcnt < $lrec} {			;#do for all middle records (not first or last)
            append body "insert into $table [rule_infields $fields [concat $ffields $keyfield rid]];\n"
#       } else {					;#nothing for last record (processed in rule below instead)
        }
        set kflist [concat new.$keyfield $kflist]
        incr rcnt
    }

    function "${view}_insfunc(new $view)" $view "returns $fkeytype language plpgsql security definer as \$\$
    declare rid $fkeytype default coalesce([join $kflist ,]); begin\n    $body\n    return rid;\n    end;\$\$;"

#Can't find a good way to generate a "returning" record, "returning *" returns what is in our insert (only the last table) and we have to match the entire view record field list exactly in name and type.
#set aflist [list user_ent null::varchar null::varchar null::varchar null::varchar null::varchar null::varchar null::varchar null::varchar null::varchar null::date null::varchar null::boolean null::boolean null::boolean null::varchar null::varchar null::varchar null::int null::text null::text null::text *]
#puts "RULE:insert into $table [rule_infields $fields [concat $ffields $keyfield ${view}_insfunc(new)]] returning [join $aflist ,];"
    rule [translit . _ $view]_insrule [list ${view}_insfunc($view)] "on insert to $view do instead\n
        insert into $table [rule_infields $fields [concat $ffields $keyfield ${view}_insfunc(new)]];"
    return {}
}

# Insert on multiple joined tables with an auto generated key (alternate implementation)
# This is implemented as a view trigger firing instead of the insert
# This does not return sql--it creates wyseman objects directly
# Table Record: {table_name {fields to insert} primary_key {fields with forced values}
#    fields:	columns to insert, if necessary in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to receive a forced value on each insert
#   ufields:	fields to update if the specified record (in the first table) already exists
#----------------------------------------------------------------
proc trig_inmulta {view tabrecs} {
    set rcnt 0
    set lrec [expr [llength $tabrecs] - 1]		;#last record we will consider
    set kflist {}					;#list of fields to find primary key in
    foreach tabrec $tabrecs {				;#for each table
        lassign $tabrec table fields keyfield ffields ufields
#puts "table:$table fields:$fields\n  keyfield:$keyfield ffields:$ffields ufields:$ufields"
        if {[llength $keyfield] > 1} {lassign $keyfield keyfield keytype} else {set keytype {int}}	;#can specify type of primary key if not integer
        if {$rcnt == 0} {				;#only do for first record
            set    body "if exists (select $keyfield from $table where $keyfield = rid) then\n"
            append body "        update $table set [rule_upfields {} $ufields] where [fld_list_eq $keyfield new { and }];\n\n"
            append body "    else\n"
#            append body "        execute (select 'new.active = true; new.country = null');\n"
            append body "        execute 'select string_agg(val,'','') from wm.column_def where obj = ''$view'';' into str;\n"
#            append body "        raise notice 'ts:%', str;\n"
            append body "        execute 'select ' || str || ';' into new using new;\n"
            append body "        insert into $table [rule_infields $fields $ffields] returning into new.$keyfield $keyfield;\n"
            append body "    end if;\n"
            set fkeyfield $keyfield
            set fkeytype $keytype
        } elseif {$rcnt <= $lrec} {			;#do for remaining records
            append body "insert into $table [rule_infields $fields [concat $ffields $keyfield new.id]];\n"
        }
        set kflist [concat new.$keyfield $kflist]
        incr rcnt
    }

    set func "returns trigger language plpgsql security definer as \$\$\ndeclare\n  rid $fkeytype default coalesce([join $kflist ,]);  str varchar;\nbegin\n    $body\n    return new;\n    end;\$\$;"
#puts "\nFunc:$func"
    function "${view}_insfunc()" $view $func

    trigger [translit . _ $view]_tr_ins [list ${view}_insfunc()] "instead of insert on $view for each row execute procedure ${view}_insfunc();"
    return {}
}

# Create the field list for an update rule: f1=new.v1, f2=new.v2, ... fn=new.vn
#----------------------------------------------------------------
proc rule_upfields {fields ffields} {
    if {$ffields != {}} {array set ff $ffields}
    foreach f $fields {
        if {[info exists ff($f)]} {		;#if a forced field given
            lappend fvals "$f = $ff($f)"	;#use it
        } else {
            lappend fvals "$f = new.$f"		;#else the default: field = new.field
        }
    }
    foreach {col val} $ffields {		;#any columns in force list not in original field list?
        if {![lcontain $fields $col]} {
            lappend fvals "$col = $val"
        }
    }
    return [join $fvals ,]
}

# Update on multiple joined tables
# Produce a separate rule for each table needing an update
# Produce an additional insert in the case where a record doesn't exist yet
#    fields:	columns to update in the specified table
#  keyfield:	columns that form primary key in specified table
#   ffields:	fields to receive a forced value on each update
#     where:	expression that must be true in order for the specified table update rule to fire
#   efields:	fields to insert to if the specified table doesn't yet contain a linked record
#  effields:	fields to insert a forced value to if the specified table doesn't yet contain a linked record
#----------------------------------------------------------------
proc rule_upmulti {view tabrecs} {
    set vcnt 1
    set sql {}
    foreach tabrec $tabrecs {
        lassign $tabrec table fields keyfield ffields where efields effields
#puts "Table:$table fields:$fields keyfield:$keyfield ffields:$ffields\n  where:$where efields:$efields effields:$effields"
        if {$vcnt == 1} {set ai {instead}} else {set ai {also}}
        append sql "create rule [translit . _ $view]_update_$vcnt as on update to $view\n"
        if {$where != {}} {append sql "where $where" "\n"}
        append sql "do $ai update $table set [rule_upfields $fields $ffields] where [fld_list_eq $keyfield old { and }];\n\n"
        incr vcnt
        
        if {$where != {} && $efields != {}} {		;#we also need a case where the record does not exist for update
            append sql "create rule [translit . _ $view]_update_$vcnt as on update to $view\n"
            if {$where != {}} {append sql "where not ($where)" "\n"}
            append sql "do also insert into $table [rule_infields $efields $effields];\n\n"
            incr vcnt
        }
    }
    return $sql
}

# Delete from view with multiple joined tables
#----------------------------------------------------------------
proc rule_demulti {view tabrecs} {
    set vcnt 1
    set lrec [expr [llength $tabrecs] - 1]	;#last record we will consider
    set sql {}
    foreach tabrec $tabrecs {
        lassign $tabrec table keyfield where
#puts "Table:$table keyfield:$keyfield where:$where"
        if {$vcnt == 1 && $where != {}} {
            append sql "create rule [translit . _ $view]_delete_0 as on delete to $view do instead nothing;\n    "
        }
#puts " vcnt:$vcnt lrec:$lrec"
        if {$vcnt == 1 || $vcnt >= $lrec} {set ai {instead}} else {set ai {also}}
        append sql "create rule [translit . _ $view]_delete_$vcnt as on delete to $view\n"
        if {$where != {}} {append sql "where $where" "\n"}
        append sql "do $ai delete from $table where [fld_list_eq $keyfield old { and }];\n    "
        incr vcnt
    }
    return $sql
}

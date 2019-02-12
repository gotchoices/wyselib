# Implement insert,update,delete triggers on a view which joins multiple tables
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------
#TODO:
#X- implement for prod.prod_v_vers
#X- generalize for use elsewhere
#- test insert
#- test update
#- test delete
#- implement conditionals for insert, update, delete
#- 

# We will refer to a hdr table and an itm table.  This terminology is used generally only
# to mean that there could (and probably will) be multiple item records for one header record.
# 
# When inserting:
# hdr_id	|  item_id	|	header		item
#----------------------------------------------------------------------------------------
# null		|  null		|	insert		insert		OK
# null		|  given	|	insert		insert		ignore given item
# given		|  null	 	|	update		insert		OK
# given		|  given 	|	update		insert		ignore given item
#
# When updating:
# hdr_id	|  item_id	|	header		item
#----------------------------------------------------------------------------------------
# null		|  ?	 	|	nop		nop		No header, ignore
# given		|  null	 	|	update		insert		create missing item
# given		|  given 	|	update		update		simple update
#
# When deleting:
# hdr_id	|  item_id	|	header		item
#----------------------------------------------------------------------------------------
# null	?	|  ?	 	|	nop		nop		No header, ignore
# given		|  null	 	|	delete		nop			
# given		|  given 	|	delete if last	delete
#

namespace eval splitview {
set db {
    function ${view}_tf_ins() {$view} {
      returns trigger language plpgsql security definer as \$\$
        begin
$di         if not ($ins_whe) then return null; end if;
            if [null_list $hdr_pk new and] then			-- if no PK fields given
                insert into $hdr_tab ([fld_list $hdr_ins_npk]) values ([ins_list $hdr_ins_npk $hdr_ins_for]) returning into $hdr_ret_new $hdr_ret;
            elseif not exists (select * from $hdr_tab where [fld_list_eq $hdr_pk new { and }]) then		-- at least a partial PK but no header exists yet
                insert into $hdr_tab ([fld_list $hdr_ins]) values ([ins_list $hdr_ins $hdr_ins_for]) returning into $hdr_ret_new $hdr_ret;
            else
                update $hdr_tab set $hdr_upd_list where [fld_list_eq $hdr_pk new { and }] returning into $hdr_ret_new $hdr_ret;
            end if;
            insert into $itm_tab ($itm_ins_fields) values ($itm_ins_values) $itm_rcl;
            return new;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_ins] {} {instead of insert on $view for each row execute procedure ${view}_tf_ins();}

    function ${view}_tf_upd() {$view} {
      returns trigger language plpgsql security definer as \$\$
        declare
            ret		record;
        begin
$du         if not ($upd_whe) then return null; end if;
            if [null_list $hdr_pk] then				-- if no (valid) existing header record specified
                return null;
            elseif [null_list $view_pk] then				-- if no item record specified
                insert into $itm_tab ($itm_ins_fields) values ($itm_ins_values) $itm_rcl;
                ret := new;
            elseif not [samelist {*}$itm_upd] then
                update $itm_tab set $itm_upd_list where [fld_list_eq $itm_pk old { and } $itm_key_for] $itm_rcl;
                ret := new;
            end if;
            if not [samelist {*}$hdr_upd] then
                update $hdr_tab set $hdr_upd_list where [fld_list_eq $hdr_pk old { and }] returning into $hdr_ret_new $hdr_ret;
                ret := new;
            end if;
            return ret;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_upd] {} {instead of update on $view for each row execute procedure ${view}_tf_upd();}

    function ${view}_tf_del() {$view} {
      returns trigger language plpgsql security definer as \$\$
        begin
$dd         if not ($del_whe) then return null; end if;
            if [null_list $hdr_pk old] then				-- if no (valid) existing header record specified
                return null;
            end if;
            if [null_list $view_pk old and not] then				-- if an item record specified
                delete from $itm_tab where [fld_list_eq $itm_pk old { and } $itm_key_for];
            end if;
            if not exists (select * from $itm_tab where [fld_list_eq $itm_key_ref old { and } $itm_key_for]) then	-- if no more items left, delete header too
                delete from $hdr_tab where [fld_list_eq $hdr_pk old { and }];
            end if;
            return old;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_del] {} {instead of delete on $view for each row execute procedure ${view}_tf_del();}
}}

# Various field types in tables
#----------------------------------------------------------------------------------------
# regular:	These hdr or itm fields have no special key meanings.  The user can typically insert and update them.
# hdr key:	The header primary key.  They may or may not appear in the insert/update list.  
# itm key:	The item primary key.  Part of this will probably refer to the hdr PK but with a different name field.  That field may not be present in the field select list (and hence the 'new' record).
# ins force:	Fields (hdr or itm) to force a value into on insert
# upd force:	Fields (hdr or itm) to force a value into on update

# Build all triggers for a view that joins two tables
#----------------------------------------------------------------
proc splitview::triggers {view view_pk hdr itm {upd_whe {}} {del_whe {}} {ins_whe {}}} {
#puts "view_pk:$view_pk upd_whe:$upd_whe del_whe:$del_whe"
    foreach v {hdr itm} {
        argform {table primary ins.columns ins.force upd.force upd.columns} $v
        argnorm {{table 1 tab} {primarykey 1 pk} {ins.columns 5 ins} {ins.force 5 ins_for} {upd.force 5 upd_for} {upd.columns 5 upd}} $v
        foreach s {tab pk ins ins_for upd_for upd} {set ${v}_$s [xswitchs $s $v]
#puts "var:${v}_$s: [subst \$${v}_$s]"
        }
    }
    if {$del_whe == {}} {set del_whe $upd_whe}						;#default delete to same condition as update
    if {$hdr_upd == {}} {set hdr_upd $hdr_ins}						;#default to update fields same as insert fields
    if {$itm_upd == {}} {set itm_upd $itm_ins}

    if {$upd_whe == {}} {set du {--}} else {set du {  }}
    if {$del_whe == {}} {set dd {--}} else {set dd {  }}
    if {$ins_whe == {}} {set di {--}} else {set di {  }}
    
    set x 0; foreach p $hdr_pk {							;#compare key fields in the header and item tables
        set f [lindex $itm_pk $x]
        if {$f != $p} {									;#if key fields have different names
            lappend itm_ins_for $f new.$p						;#make force clauses to substitute proper field name on item table
            lappend itm_upd_for $f new.$p
            lappend itm_key_for $f old.$p
            lappend itm_key_ref $f
        }
        incr x
    }
    
    foreach {f v} $hdr_ins_for {if {![lcontain $hdr_ins $f]} {lappend hdr_ins $f}}	;#make sure all forced header fields are in the header insert list
    foreach {f v} $itm_ins_for {if {![lcontain $itm_ins $f]} {lappend itm_ins $f}}	;#ditto itm

    foreach {f} $hdr_ins {if {![lcontain $hdr_pk $f]} {lappend hdr_ins_npk $f}}		;#insert fields not including primary key

    set itm_ret {}
    foreach f $hdr_pk {if {[lcontain $view_pk $f]} {lappend hdr_ret $f}}		;#list of header fields also in view primary key
    set hdr_ret_new	[fld_list $hdr_ret new]
    
    foreach f $itm_pk {if {[lcontain $view_pk $f]} {lappend itm_ret $f}}		;#ditto itm
    set itm_ret_new	[fld_list $itm_ret new]
    if {$itm_ret == {}} {set itm_rcl {}} else {set itm_rcl "returning into $itm_ret_new $itm_ret"}
#puts "hdr_ret:$hdr_ret itm: $itm_rcl $itm_ret"

    set hdr_upd_list	[upd_list $hdr_upd $hdr_upd_for]

    set itm_ins_fields	[fld_list $itm_ins]
    set itm_ins_values	[ins_list $itm_ins $itm_ins_for]
    set itm_upd_list	[upd_list $itm_upd $itm_upd_for]
    
    set tpt [subst $splitview::db]					;#process the sql objects template
#puts "tpt:$tpt"
    eval $tpt
}

# Audit tables
#----------------------------------------------------------------
# Copyright WyattERP all rights reserved
#TODO:
#- make template for table and triggers
#- implement as a macro
#- 
#----------------------------------------------------------------
# The objective of this module is to retain a history of all prior values of
# selected columns.  The module is implemented as a macro in order to minimize
# the amount of coding needed.  The idea is to build your normal tables and then
# include an audit macro at the end which will build a table to contain the audit
# data from the base table.
# 
# Each audit table will have a name identical to the table it is auditing with
# the additional suffix of: _audit.
# 
# The audit table will have primary key column(s) that are identical to the
# base table except there is also a sequence number as part of the primary
# key.  So each record in the base table can have many related records in the
# audit table, sequentially numbered as changes are made to the record.
# 
# The audit table columns that share the primary key with the base table would
# typically consist of a foriegn key reference to the base table.  But this
# would prevent the audit records from remaining after the record in the base
# table has been deleted.  So we will not include an explicit FK reference
# even though it is implied for records where the base record still exists.
# 
# Implementation
# #----------------------------------------------------------------
# The audit table will capture data that is about to be overwritten or deleted
# in the base table.  This is done one column at a time.  So if multiple columns
# in the base table are being changed, the audit table will record a separate
# row for each column changed.
# 
# All values from the base table will be casted into a string and stored in a
# single column in the audit table.  This implies that the data will lose its
# explicit typing and may not be available for automated comparisons with the
# base table (at least without recasting it back to its original type).
# 
# Since the intended purpose is human inspection, this should not typically be
# a problem.
# 
# Name clashes
#----------------------------------------------------------------
# Since we do not know the names that may be chosen for the primary key we will
# prefix all column names in the audit table with "a_" in order to reduce the
# chance of a name collision.
# 
# Audit table columns
#----------------------------------------------------------------
# Base_PK	Whatever column names are inherited from the base table
# a_seq		0..n, sequentially numbered
# a_who		ID of the user who made the change
# a_stamp	When the base row was modified
# a_action	Update or Delete
# a_column	Name of the column recorded
# a_value	Prior value (contents) of the column

package require csv
#----------------------------------------------------------------
namespace eval audit {

    #Create a template of DB objects that will be used to record audit data for a single regular table
    set db_objects	{
        table %T_audit {audit_type %E %T} {%S
          , a_seq	int		check (a_seq >= 0)
          , a_date	timestamp(0)	not null default current_timestamp
          , a_by	name		not null default session_user references %E (username) on update cascade
          , a_action	audit_type	not null default 'update'
          , a_column	varchar		not null
          , a_value	varchar
     	  , a_reason	text
          , primary key (%K,a_seq)
        } -grant {{%V	{} {} {s}}}
        index {} %T_audit a_column

        function %T_audit_tf_bi() {%T_audit} {		--Call when a new audit record is generated
          returns trigger language plpgsql security definer as $$
            begin
                if new.a_seq is null then		--Generate unique audit sequence number
                    select into new.a_seq coalesce(max(a_seq)+1,0) from %T_audit where %W;
                end if;
                return new;
            end;
        $$;}
        trigger [translit . _ {%T}]_audit_tr_bi {} {before insert on %T_audit for each row execute procedure %T_audit_tf_bi();}

        function %T_tf_audit_u() {%T %T_audit} {		--Call when a record is updated in the audited table
          returns trigger language plpgsql security definer as $$
            begin
                %U;						--A set of conditional insert statements (if the field changed)
                return new;
            end;
        $$;}
        trigger [translit . _ {%T}]_tr_audit_u {} {after update on %T for each row execute procedure %T_tf_audit_u();}

        function %T_tf_audit_d() {%T %T_audit} {		--Call when a record is deleted in the audited table
          returns trigger language plpgsql security definer as $$
            begin
                %D;						--A set of unconditional insert statements
                return old;
            end;
        $$;}
        trigger [translit . _ {%T}]_tr_audit_d {} {after delete on %T for each row execute procedure %T_tf_audit_d();}
    }
}

# Basic account types
#----------------------------------------------------------------
other audit_type {} {
    create type audit_type as enum ('update','delete');
} {drop type if exists audit_type}

# Procedure to build an audit table and its associated triggers
#----------------------------------------------------------------
proc audit::audit {table cols {priv {}} {users base.ent}} {
    set create [field $table create]				;#get table's sql create script from wyseman, skip up through opening paren
    if {![regexp {create table [a-zA-Z_.]+ \((.*)\).*;} $create junk body]} {
        error "Can't find sql body for table: $table"
        return
    }
    set obody {}						;#accumulate parsed characters
    set nest 0							;#how deeply nested in quotes, parenthesis
    set next($nest) {)}						;#what delimiter to expect next
    for {set i 0} {$i < [string length $body]} {incr i} {	;#for each character in table body
        if {[set c [string index $body $i]] == $next($nest)} {
            if {$nest == 0} break				;#found end of table body
            incr nest -1
#puts "pop nest:$nest"
        } elseif {$c == "\{"} {
#puts "push \" nest:$nest next:$next($nest)"
            set next([incr nest]) {"}
        } elseif {$c == {(}} {
            set next([incr nest]) {)}
#puts "push ( nest:$nest next:$next($nest)"
        } elseif {$c == {,}} {
#puts "nest:$nest c:$c"
            if {$nest == 0} {set c {|}}				;#map outer commas to pipes for split later
        }
        append obody $c
    }
    
#puts " obody:$obody"
    lassign {} pk pksql
    foreach ln [split $obody |] {	;#for each line of table's sql create script
#puts "  ln:$ln"
        if {![regexp {([a-zA-Z0-9_]+)[ \t]+([a-zA-Z0-9_]+)[ \t]*(.*)} $ln junk p1 p2 rest]} continue
#puts "    p1:$p1 p2:$p2 rest:$rest"
        set coltypes($p1) $p2					;#remember each column type
        if {[regexp -nocase {primary key} $rest]} {		;#if this column is our primary key
            set pk $p1						;#remember what it is
            lappend pksql "$p1 $p2"				;#and how to build it
            break
        } elseif {[regexp -nocase {primary} $p1] && [regexp -nocase {key} $p2] && [regexp -nocase {\((.*)\)} $rest junk pkcols]} {
#puts "pkcols:$pkcols"
            regsub -all { } $pkcols {} pkcols
            set pk [split $pkcols ,]
            foreach pkcol $pk {lappend pksql "$pkcol $coltypes($pkcol)"}
            break
        }
    }
    if {$pk == {}} {
        error "Can't parse locate primary key for table: $table"
        return
    }
#puts "      pk:$pk pksql:$pksql"

    lassign {} ulist dlist
    foreach c $cols {
        set i1 "insert into ${table}_audit ([join $pk ,],a_date,a_by,a_action,a_column,a_value) values ([fld_list $pk old],transaction_timestamp(),session_user"
        set i2 "'$c',old.${c}::varchar)"
        lappend dlist "$i1,'delete',$i2"
        lappend ulist "if new.$c is distinct from old.$c then $i1,'update',$i2; end if"
    }

    set w [fld_list_eq $pk new { and }]		;#make primary key where clause
    set tpt $audit::db_objects			;#load up the sql object template
    foreach {s v} [list E $users T $table K [join $pk ,] S [join $pksql ,] W $w U [join $ulist ";\n\t\t"] D [join $dlist ";\n\t\t"] V $priv] {	;#substitute values for our object set
        regsub -all "%$s" $tpt "$v" tpt
    }
#puts "tpt:$tpt"
    eval $tpt
}

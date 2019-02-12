# Implement insert,update,delete triggers on a single table view
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------
#TODO:
#- 

namespace eval view {
  set dbi {
    function ${view}_tf_ins() {$view} {
      returns trigger language plpgsql security definer as \$\$
        begin
$di         if not ($ins_where) then return null; end if;
            insert into $table ([fld_list $ins_columns]) values ([ins_list $ins_columns $ins_force]) returning into [fld_list $pkey new] [join $pkey ,];
            return new;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_ins] {} {instead of insert on $view for each row execute procedure ${view}_tf_ins();}
  }

  set dbu {
    function ${view}_tf_upd() {$view} {
      returns trigger language plpgsql security definer  as \$\$
        begin
$du         if not ($upd_where) then return null; end if;
            if [samelist {*}$upd_columns] then return null; end if;
            update $table set [upd_list $upd_columns $upd_force] where [fld_list_eq $pkey old { and }] returning into [fld_list $pkey new] [join $pkey ,];
            return new;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_upd] {} {instead of update on $view for each row execute procedure ${view}_tf_upd();}
  }

  set dbd {
    function ${view}_tf_del() {$view} {
      returns trigger language plpgsql security definer as \$\$
        begin
$dd         if not ($del_where) then return null; end if;
            delete from $table where [fld_list_eq $pkey old { and }];
            return old;
        end;
    \$\$;}
    trigger [translit . _ ${view}_tr_del] {} {instead of delete on $view for each row execute procedure ${view}_tf_del();}
  }
}

# Build standard insert, update, delete triggers for a view
#----------------------------------------------------------------
proc view::triggers {view table pkey args} {
    argform {columns insert update delete} args
    argnorm {{columns 1} {insert 1} {update 1} {delete 1}} args
    foreach s {columns insert update delete} {set $s [xswitchs $s args]}
#debug columns insert update delete

    if {$insert != {}} {
        argform {columns where force} insert
        argnorm {{columns 1} {where 1} {force 1}} insert
        foreach s {columns where force} {set ins_$s [xswitchs $s insert]}
        if {$ins_columns == {}} {set ins_columns $columns}
        if {$ins_where == {}} {set di {--}} else {set di {  }}
        foreach {f v} $ins_force {if {![lcontain $ins_columns $f]} {lappend ins_columns $f}}	;#make sure all forced header fields are in the header insert list
#puts "dbi:[subst $view::dbi]"
        eval [subst $view::dbi]
    }
    if {$update != {}} {
        argform {columns where force} update
        argnorm {{columns 1} {where 1} {force 1}} update
        foreach s {columns where force} {set upd_$s [xswitchs $s update]}
        if {$upd_columns == {}} {set upd_columns $columns}
        if {$upd_where == {}} {set du {--}} else {set du {  }}
#puts "dbu:[subst $view::dbu]"
        eval [subst $view::dbu]
    }
    if {$delete != {}} {
        argform {where} delete
        argnorm {{where 1}} delete
        foreach s {where} {set del_$s [xswitchs $s delete]}
        if {$del_where == {}} {set dd {--}} else {set dd {  }}
#puts "dbd:[subst $view::dbd]"
        eval [subst $view::dbd]
    }
}

# Support functions for product schema
#------------------------------------------
#Copyright WyattERP, all other rights reserved
package provide wyselib 0.20

#TODO:
#- finish parm_edit
#- 

dew::scm units {-eval {sql::qlist "select abbr,descr from prod.unit order by descr"} -f unit -f descr -token unit -tag scm_unit}
dew::scm prod_type {-eval {sql::qlist "select type,level,descr from prod.type order by level,type"} -f type -f level -f descr -token type -tag scm_prod_type}
dew::scm doc_sel {-eval {sql::qlist "select id,name from doc.doc_v order by name"} -f id -f name -token id -tag scm_doc_id}
dew::scm proc_sel {-eval {sql::qlist "select idx,oper_r,descr from prod.proc_v where base_rr = '[sequ proce get base_rr]' order by idx"} -f idx -f oper_r -f descr -token idx -tag scm_next_idx}

namespace eval prod {
    namespace export build proc_build edit_build parm_edit oper_menu type_menu unit_menu dtyp_menu
#    namespace export base_price parm_edit norm_parms spec_price cfig edit_parms split_part mtr_schedule mtr_by_part time_history
#    variable v
    variable cfig
#    set v(int) {}
#    set v(val) {}

    set cfig(unite) "-table prod.unit $wyselib::dbebuts -check {f {abbr descr}}"
    set cfig(unitp) "$wyselib::dbpbuts -disp {abbr descr cmt} -load 1"

    set cfig(typee) "-table prod.type $wyselib::dbebuts -check {f {type level descr}}"
    set cfig(typep) "$wyselib::dbpbuts -disp {type level descr cmt} -load 1"

    set cfig(opere) "-table prod.oper $wyselib::dbebuts -check {f {oper descr}}"
    set cfig(operp) "$wyselib::dbpbuts -disp {oper descr} -load 1"

    set cfig(dtype) "-table prod.doc_type $wyselib::dbebuts -check {f {type descr}}"
    set cfig(dtypp) "$wyselib::dbpbuts -disp {type autolock public descr} -load 1"

#        -m {grb {Grab Basename} -s {Grab -bg orange} {oper_bgrab %w} -help {Load the the base name currently loaded in the Basename editing pane}}\

    set cfig(verse) [concat $wyselib::dbebuts {-table prod.prod_v_vers -record {{Record:} -width 15}
        -check {f {type_r name units} r descr}
        -ldr.pst {prod::vers_pst_ldr %w} -clr.pst {prod::vers_pst_clr %w} -dlr.pst {prod::vers_pst_clr %w} 
        -m {clone {Clone Base} {prod::clone_base %w} -help {Create a clone of a basename and optional import its elements}}
    }]
    set cfig(parte) [concat $wyselib::dbebuts {-table prod.part_v
        -check {f {height width length stack} r {cost}}
        -clr.pst {prod::part_pst_clr %w} -ldr.pst {prod::part_pst_ldr %w}
        -m {view {View} -s {View -bg violet} {pdoc::view_bp [%w get pnum] -type fig} -help {Quick view of this part}}
    }]
    set cfig(prodp) "-table prod.prod_v_part $wyselib::dbpbuts -disp {pnum partname rev curr descr units locked current latest} -order {partname rev}"
    
    set cfig(parme) [concat $wyselib::dbebuts {-table prod.parm_v
        -check {f {var units ptyp} r descr}
        -m {up {Move Up}   {%w func prod.parm_move -1} -help {Move the parameter one position smaller (to the left in the parameter list)}}
        -m {dn {Move Down} {%w func prod.parm_move 1}  -help {Move the parameter one position larger (to the right in the parameter list)}}
    }]
    set cfig(parmp) "$wyselib::dbpbuts -disp {pos var descr units ptyp def} -order {pos}"

#        -adr.pre {prod::parm_pre_com %w} -upr.pre {prod::parm_pre_com %w} -dlr.pre {prod::parm_pre_dlr %w}
#        -clr.pst {prod::parm_pst_clr %w} -dlr.pst {prod::parm_pst_dlr %w}\
#        -adr.pre {prod::proc_pre_com %w} -upr.pre {prod::proc_pre_com %w}

    set cfig(proce) [concat $wyselib::dbebuts {-table prod.proc_v
        -check {f {oper_r lab_time} r descr}
        -m {up {Move Up}   {%w func prod.proc_move -1} -s {Up -bg #d8e8e8} -help {Move the process one position smaller in the sequence list}}
        -m {dn {Move Down} {%w func prod.proc_move 1}  -s {Dn -bg #e8e8d8} -help {Move the process one position larger in the sequence list}}
    }]
    set cfig(procp) "$wyselib::dbpbuts -disp {base_rr rev_r idx next oper_r idescr lab_time mach_time path} -order path"

    set cfig(notee) [concat $wyselib::dbebuts {-table prod.note_v
        -adr.pre {prod::note_pre_com %w} -upr.pre {prod::note_pre_com %w}
        -m {up {Move Up}   {%w func prod.note_move -1} -s {Up -bg #d8e8e8} -help {Move the notes component one position smaller in the list}}
        -m {dn {Move Down} {%w func prod.note_move 1}  -s {Dn -bg #e8e8d8} -help {Move the notes component one position larger in the list}}
    }]
    set cfig(notep) "$wyselib::dbpbuts -disp {base_rrr rev_rr idx_r seq type doc_r descr} -order {base_rrr rev_rr idx_r seq}"

    set cfig(bomse) [concat $wyselib::dbebuts {-table prod.boms_v
        -check {f quant comp_base}
        -adr.pre {prod::boms_pre_com %w} -upr.pre {prod::boms_pre_com %w}
        -m {up {Move Up}   {%w func prod.boms_move -1} -s {Up -bg #d8e8e8} -help {Move the BOM element one position smaller in the list}}
        -m {dn {Move Down} {%w func prod.boms_move 1}  -s {Dn -bg #e8e8d8} -help {Move the BOM element one position larger in the list}}
    }]
    set cfig(bomsp) "$wyselib::dbpbuts -disp {base_rr rev_r idx quant compname proc cmt} -order {base_rr rev_r idx}"
}

# Can we get rid of these?
#----------------------------------------------------
proc prod::part_pst_clr {w} {return 1}
proc prod::part_pst_dlr {w} {return 1}
proc prod::parm_pst_clr {w} {return 1}
proc prod::parm_pst_dlr {w} {return 1}
proc prod::parm_pre_dlr {w} {return 1}

# Menu/builder: units
#----------------------------------------------------
proc prod::unit_build {w} {return [top::dbep $w $prod::cfig(unite) $prod::cfig(unitp)]}
top::menu prod unit {} {Standard Units} {Open a toplevel window for viewing/editing the standard defined units for all products}

# Menu/builder: product types
#----------------------------------------------------
proc prod::type_build {w} {return [top::dbep $w $prod::cfig(typee) $prod::cfig(typep)]}
top::menu prod type {} {Product Types} {Open a toplevel window for viewing/editing defined product types.  The type forms a prefix for all product basenames.}

# Menu/builder: operations
#----------------------------------------------------
proc prod::oper_build {w} {return [top::dbep $w $prod::cfig(opere) $prod::cfig(operp)]}
top::menu prod oper {} {Standard Operations} {Open a toplevel window for viewing/editing standard operations}

# Menu/builder: product document types
#----------------------------------------------------
proc prod::dtyp_build {w} {return [top::dbep $w $prod::cfig(dtype) $prod::cfig(dtypp)]}
top::menu prod dtyp {} {Document Types} {Open a toplevel window for viewing/editing defined product document types.}

# After loading a part
#------------------------------------------
proc prod::part_pst_ldr {w} {
    set t [mytop $w]
    if {[$t verse g base] != [$w get base_r]} {		;#if correct base not already loaded, load it (maybe we loaded a part directly...)
        $t verse load -where "base = '[$w get base_r]' and latest"
    }
}

# Items common to to add/delete for processes
#----------------------------------------
proc prod::proc_pre_com {w} {

   return 1
}

# Items common to add/update
#------------------------------------------
proc prod::note_pre_com {w} {
    $w force type descr
    if {[$w g type] == {fig}} {$w force doc_r}
    return ?
}

# Items common to add/update
#------------------------------------------
proc prod::boms_pre_com {w} {
    set p [prod verse w]
    lassign [$p pk] base rev
#debug p base rev
    $w set base_rr $base	;# use this instead of -master {prod verse} because of 2 FK's
    $w set rev_r $rev
    return ?
}

# Ater loading a base version (use instead of -slave {boms bomsp} because of 2 FK's)
#------------------------------------------
proc prod::vers_pst_ldr {w} {
    catch {boms bomsp load -where "base_rr = '[$w get base_r]' and rev_r = [$w get rev]"}
}
proc prod::vers_pst_clr {w} {catch {boms bomsp clear}}

# When executing a record in the unified product preview
#----------------------------------------------------
proc prod::prod_load {w t {ids {}}} {
puts "prod_load w:$w t:$t ids:$ids"
    if {$ids == {}} {set ids [lindex [$w keys] 0]}			;#consider only the first record
    lassign $ids base rev pnum
debug base rev pnum
    if {$pnum == {}} {
        $t.e.pe clear 
        $t.e.ve load "$base $rev"
    } else {
        $t.e.ve load "$base $rev"
        $t.e.pe load $pnum
    }
}

# Allow the user to edit individual parameters
#----------------------------------------------------
proc prod::parm_edit {w} {
    variable cfig
    variable v

xxxxxxxxxxxxx
    set d [mypar $w Mdew]
    set base [$d g base_r]
    set rev  [$d g rev]
puts "parm_edit w:$w d:$d"
    if {[set base [[mypar $w Mdew] g base_r]] == {}} {
        set base [[$w mytop] verse g base]
    }
puts "  base:$base"
return
    set darr {}
    foreach r1 [sql::qlist "select var,units,ptyp,descr,def from prod::parm_v where base = '$base' order by pos"] {
        lassign $r1 var units ptyp descr def
        if {$ptyp == {str}} {
            set data [list -f value -f description -token value -data [sql::qlist "select value, descr from prod::sval where base_rrr = '$base' and var = '$var' order by var"]]
            lappend darr [list "$descr ($units) $var=" -spf scm -data $data]
        } else {
            lappend darr [list "$descr ($units) $var=" -spf clc -just r]
        }
    }
#puts "edit_parms: w:$w base:$base darr:$darr"
    if {$base == {}} {dia::err "Please load a base and/or part first"; return}
    if {$darr == {}} {dia::err "Base: $base has no parameters defined"; return}
    dew::edarr $w -sql 1 -descr $darr -force [llength $darr] -msg "Assign Parameters for base: $base"
}

# Function to clone base name
#--------------------------------------------------
proc prod::clone_base {w} {
    lappend parr -f [list type ent 3 "0 0" Type: -ini [$w get type_r] -spf scm -data prod_type] -f [list name ent 15 "0 1" Name:]
    if {[eval dia::dia .dia_clone_base -but \{Ok Cance\} -def 0 -message \{Enter new base name\} -entry mdew::mdew -dest res -pre 0 $parr] < 0} return
   set t [lindex $res 1]
   set n [lindex $res 3]
   set c [join "$t $n" _]
   sql::exe "select prod.clone_base('$c','[$w get base]',[$w get rev])" -clear 1
   $w load "$c 1" 
   return 1
}

# Make a toplevel window for Bill of Materials
#----------------------------------------------------
top::menu prod boms Bom {Bill of Materials} {Open a new window for editing a Bill of Materials}
proc prod::boms_build {w} {
    variable cfig

    set m [$w menu w]
    $m mb tools -under 0 -help {Common functions related to this module}

    $m mb rept Reports -under 0 -help {Reports pertaining to this module}
    $m rept mi graph {Graph Part Usage} -under 0 -command "graph_part $w"

    frame $w.b
    top::add [dbe::dbe $w.b.be -pwidget $w.b.bp {*}$cfig(bomse) -bg lightgreen -master {{sequ proce}}] bomse
    top::add [dbp::dbp $w.b.bp -ewidget $w.b.be {*}$cfig(bomsp)] bomsp
        
    pack $w.b -side left -fill both -exp yes
    pack $w.b.be -side top -fill both
    pack $w.b.bp -side top -fill both -exp yes
    return 1
}

# Make a toplevel window for procedure sequences/documentation
#----------------------------------------------------
top::menu prod sequ Proc {Process Sequence} {Open a new window for editing procedure sequences and their associated production notes}
proc prod::sequ_build {w} {
    variable cfig

    set m [$w menu w]
    $m mb tools -under 0 -help {Common functions related to this module}
    $m mb rept Reports -under 0 -help {Reports pertaining to this module}
#    $m rept mi graph {Graph Part Usage} -under 0 -command "graph_part $w"

    frame $w.p
    frame $w.n
    
    top::add [dbe::dbe $w.p.pe -pwidget $w.p.pp {*}$cfig(proce) -master {{prod verse}} -slave "$w.n.np" -bg yellow] proce
    top::add [dbp::dbp $w.p.pp -ewidget $w.p.pe {*}$cfig(procp)] procp 
    top::add [dbe::dbe $w.n.ne -pwidget $w.n.np {*}$cfig(notee) -master $w.p.pe -bg violet] notee
    top::add [dbp::dbp $w.n.np -ewidget $w.n.ne {*}$cfig(notep)] notep 
    top::add [sizer::sizer $w.sz $w.p $w.n -orient v] xsize
    
    pack $w.p -side left -fill y
    pack $w.sz -side left -fill y
    pack $w.n -side left -fill both -exp yes
    pack $w.p.pe $w.n.ne -side top -fill both
    pack $w.p.pp $w.n.np -side top -fill both -exp yes
    return 1
}

# Make a main prodim editing window
#----------------------------------------------------
proc prod::build {w} {
    variable cfig

    set m [$w menu w]
    $m mb tools -under 0 -help {Common functions related to this module}

    prod::boms_menu $m tools
    prod::sequ_menu $m tools
    pdoc::pdoc_menu $m tools
    
#    $m tools mi graph {Graph Part Usage} -under 0 -command "graph_part $w"
#    $m tools mi importp {Import Parameters from a Base} -under 7 -command "imp_parms $w"
#    $m tools mi importc {Import Component List from a Base} -under 7 -command "imp_spread $w"
#    $m tools mi alph {Alphabetize Component List by Base,Parameters} -under 0 -command "alph_spread $w"
#    $m tools mi viewb {View Notes for Basename} -under 0 -command {pdoc::view_bp [%w.p.be get base]}
#    $m tools mi sep
#    $m tools mi rem {Rename Current Base} -under 0 -command "ren_base $w"
#    $m tools mi sep
#    $m tools mi promote {Promote Components} -under 4 -command "promote_spread $w"
#    if {$cfig(prof) == {}} {
#        $m tools mi packs {Standard Package Window} -under 5 -command  "top::top packwin  -title {Packaging Window} -build {build_stdpkg %w} -reopen 1"
#    }
#    if {[priv::haspriv super]} {
#        $m tools mi pricetble {Access Pricing Table} -command {acc_pricing}
#    }
#    $m tools mi camq {CAM Queue} -under 5 -help {Queue CAM programs to be used in work cells} -command "top::top camq -title {CAM Queue} -build {camq::build %w} -reopen 1"

    if {[base::priv_check super]} {
        $m mb setup -under 0 -help {Supervisor functions for the product information manager}
        prod::oper_menu $m setup
        prod::type_menu $m setup
        prod::unit_menu $m setup
        prod::dtyp_menu $m setup
    }

    $m mb rept Reports -under 0 -help {Reports pertaining to this module}
#    $m rept mi partd {Inventory Detail} -under 2 -help {Show the costs making up an inventory by date} -command {gl::invent}
#    $m rept mi partd {Part History} -under 0 -help {Show running cost and stock levels for a part number} -command {gl::part}
    
#    $m s dew::dew inv ent {Inv:} -width 3 -textv v(inv$w) -ini $::cnf(definv) -spf scm -data inve -just r -help {Working Inventory}
#    $m rept mi loadcn {Load Parts with Component List w/o Assy Notes} -command "prodim_filters $w 1" ;#"$w.p.tp load -where {elevel >= 0 and exists (select * from prd_spread m where m.base = base) and not exists (select * from prd_doc p where p.base =base and type = 'notes' and class = 'assy')}"
#    $m rept mi loadna {Load Parts w/o Assy Figures} -command "prodim_filters $w 2" ;#{.p.tp load -where {p.elevel >= 0 and not exists (select * from prd_doc where base = p.base and type = 'fig' and class = 'assy')}}
#    $m rept mi loadwbp {Load Parts containing this Base,Parm} -command "prodim_filters $w 3"


    frame $w.e
    frame $w.p
    
    top::add [dbp::dbp $w.p.pp {*}$cfig(prodp)] prodp
    top::add [dbe::dbe $w.e.ve -pwidget $w.p.pp {*}$cfig(verse) -bg red -slaves "$w.e.mp {sequ procp} {pdoc p}"] verse
    top::add [dbe::dbe $w.e.me -pwidget "$w.e.mp $w.p.pp" -master $w.e.ve {*}$cfig(parme) -bg green] parme
    top::add [dbp::dbp $w.e.mp -ewidget $w.e.me -master $w.e.ve {*}$cfig(parmp)] parmp 
    top::add [dbe::dbe $w.e.pe -pwidget $w.p.pp -master $w.e.ve {*}$cfig(parte) -bg blue] parte
    bind $w.p.pp <<Execute>> "prod::prod_load %W $w"

    pdoc::logmenu $w.e.ve
    
    pack $w.e -side left -fill y
    pack $w.p -side left -fill both -exp yes
    pack $w.e.ve $w.e.me -side top -fill both
    pack $w.e.mp -side top -fill both -exp yes
    pack $w.e.pe -side top -fill both
    pack $w.p.pp -side top -fill both -exp yes
    return 1
}


return

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Return a parameter in "standard" form for the Stocklist
#------------------------------------------
# val:	The value or expression to evaluate
# typ:	The parameter type
proc prod::norm_parm {val typ} {
#puts "norm:$val:$typ:"
    if {$val == {}} {return {}}
    if {$typ == {num}} {	;#if numeric parm, convert to decimal form
        regsub -all {[.0-9]+} $val { double(&) } val
        set val [expr $val]		;#reduce it
        regsub -all {\.0+$} $val {} val	;#lose trailing 0's
        if {[regexp {.*\.[0-9][0-9][0-9][0-9][0-9]+} $val]} {             ;#round
            set val [expr double(round($val * 10000.00)) / 10000.00]
        }
    } else {			;#insert processors for other types?
    }
    return $val
}

#Normalize a list of parameters
#----------------------------------------------------
proc prod::norm_parms {base parm} {
    set prmlist [split $parm {,}]
    set len [llength $prmlist]
    set newlist {}
    for {set i 1} {$i <= $len} {incr i} {	;#for each parm (0..N-1)
        lassign [sql::one "select ptyp from prod_parm where base = '$base' and pos = $i" "Parameter $i"] ptyp
        set val [norm_parm [lindex $prmlist [expr $i - 1]] $ptyp]
        lappend newlist $val
    }
    return [join $newlist {,}]
}

# Allow the user to edit a parameter list for a base
#------------------------------------------
proc prod::parm_edit {base {parm {}}} {
    variable cfig
    set vnam {}
    set strgs {}
    set cfig(padx.edit_parms) {1m}
    set targs {-width -1}
    set i 0; foreach prm [sql::qlist "select pos,var,ptyp,descr from prod_parm where base = '$base' order by pos"] {
        lassign $prm pos var ptyp descr
#        lappend vnams x_$var
#        lappend strgs "$descr $var:"
#        set ptypes(x_$var) $ptyp		;#remember parm type
#        set x_$var [lindex [split $parm {,}] $i]	;#init value
        if {[dia::query "Please enter: $descr $var" val 0 OK Cancel] < 0} {return 0}
        lappend vnam $ptyp
        lappend vnam $val
#        lappend parr -f [list  x_$var ent 14 "0 $i" -title "$descr $var:"]
#        incr i
    }
    if {$vnam == {}} {return {}}
#    if {[llength $strgs] == 1} {set strgs [lindex $strgs 0]}
#    if {[eval dia::dia .edit_parms \{OK Cancel\} -def 0 -mess \{Edit Package Parameters:\} -dest vnam -entry mdew::mdew -pre 0 $parr] < 0} {return 0}
    set prmlst {}; foreach {t v} $vnam {
        lappend prmlst [norm_parm $v $t]
    }
    return [join $prmlst {,}]
}

#Break a fully qualified part name into a base and parm (returns {base parm} or just base)
#valid forms: p:base(a1,a2) base(a1,a2)
#------------------------------------------
proc prod::split_part {name} {
    regsub -all "\[ \t\n)]" $name {} name	;#lose spaces and )
    if {![regexp {^.:} $name]} {set name "a:$name"}	;#add on a:
    regsub {\(} $name " " n			;#separate base and parm
    lassign $n base parm
    if {[regexp {\(} $name]} {
        return [list $base $parm]
    } else {
        return $base
    }
}

# Support functions for basic wyseman accounting modules
#------------------------------------------
#Copyright WyattERP: GNU GPL Ver 3; see: License in root of this package
package provide wyselib 0.20

#TODO:
#- Fix newch button
#-     summ
#-     stats
#-     close
#- Build a sample project tree for Kyle
#- How to make special linked projects like:
#-   entity
#-   asset
#-   cash
#- 
#- 

namespace eval proj {
    namespace export where_fam ptyp_menu proj_menu
    variable cfig
    
    set cfig(ptype) "-table acct.proj_type $wyselib::dbebuts -check {f {code name}}"
    set cfig(ptypp) "$wyselib::dbpbuts -disp {code type_name descr acct} -order code -load 1"

    set cfig(proje) [list -table acct.proj_v {*}$wyselib::dbebuts -adr.pre proj::proj_pre_adr -upr.pre proj::proj_pre_com \
      -slaves {{passwd p} proj::tree proj::summary proj::stats}\
      -m {par   {Load Parent}        -command {%w load [%w get par]} -s {Par} -help "Load the parent project of the current project"}\
      -m {child {Show Children}      -command {%w pwidget load -where "par = '[%w get code]'"} -s {Child} -help "Show the immediate children of the current project"}\
      -m {prog  {Show Progeny}       -command {%w pwidget load -where [proj::where_fam [%w pk]]} -s {Family} -help "Show the children, grandchildren, etc. along with the current project"}\
      -m {newch {Prepare New Child}  -command {proj::child %w} -s {New} -help "Prepare the entry to create a new project as child of the current project"}\
      -m {summ  {Summary Report}     -command {proj::summary %w} -s {Sum}   -help "Show revenues and expenses for the current project and (optionally) its children and/or progeny"}\
      -m {stats {Statistics Report}  -command {proj::stats %w}   -s {Stats} -help "Show key metrics for the current project and (optionally) its progeny"}\
      -m {close {Close Project}	     -command {%w set status {clsd}; %w update} -s {Close} -help {Mark the current project as completed}}\
    ]
    set cfig(projp) "$wyselib::dbpbuts -disp {code iname descr par owner own_name} -order fpath"

    set cfig(pwde) "proj_passwd_v_me $wyselib::dbebuts -check {f passwd}"
    set cfig(pwdp) "-master {m proje} $wyselib::dbpbuts -disp {emple empname proj_code proname passwd valid}"
}

# Return a where clause for finding the progeny of a given project
#------------------------------------------
proc proj::where_fam {code {inclme 1}} {
    if {$inclme} {set comp {>=}} else {set comp {>}}
    return "idx $comp acct.proj_idx($code) and idx <= acct.proj_mxc($code)"
}

#Prepare to create a child of the current project
#----------------------------------------------------
proc proj::child {w} {
    set par [$w get code]
    $w clear -prompt no
    $w set par $par
}

#Checks common to addrec and updrec
#----------------------------------------------------
proc proj::proj_pre_com {w} {
    if {![base::priv_check]} {return 0}
    $w force type name owner bdate par
#    $w request descr
#FIXME:
#    if {[lcontain {job ots} [$w get ptype]]} {$w force tmarg}
#    if {[lcontain {ccb adm war} [$w get ptype]]} {$w set tmarg {}}
    return ?
}

#Prepare to add a new project
#----------------------------------------------------
proc proj::proj_pre_adr {w} {
    $w set status {open}
    return [proj_pre_com $w]
}

# Lookup a project and its type from a scrolled menu
#------------------------------------------
#proc proj::lookup {w ttag ptag} {
##puts "proj::lookup w:$w ttag:$ttag ptag:$ptag"
#    set fullproj [$w get "$ttag $ptag"]
#    if {[scm::dia {Select Project:} -dest fullproj \
#        -eval {sql::qlist "select proj_tp,proj_id,proj_name,descr from acct.proj order by proj_tp, proj_id"} \
#        -tag scm_tj_proj \
#        -f {type} -f {id} -f {descr}
#    ] < 0} return {}
#    lassign $fullproj ptyp proj
#    $w set ptyp $ptyp
#    $w set proj $proj
#}

# Construct the main window for viewing/editing project types
#----------------------------------------------------
top::menu proj ptyp {} {Project Types} {Open a toplevel window for viewing/editing standard project types}
proc proj::ptyp_build {w} {return [top::dbep $w $proj::cfig(ptype) $proj::cfig(ptypp)]}

# Construct the main window for viewing/editing projects
#----------------------------------------------------
top::menu proj proj Proj {Projects} {Open a toplevel window for viewing/editing projects}
proc proj::proj_build {w} {
    variable cfig
    set m [$w menu w]
    $m mb tools -under 0 -help {Common helpful functions for this application}
    $m tools mi passwd {Edit Passwords} -under 0 -s Passwd -help {Open a toplevel window for viewing/managing access passwords} -command "top::top passwd -title {Passwords:} -build {top::dbep %w $proj::cfig(pwde) \$::cnf(pwdp)} -reopen 1"
#    $m tools mi ftrs   {Fund Transfers} -under 0 -s Funding -help {Open a toplevel window for viewing/managing project funding transfers} -command "top::top ftrs -title {Funding:} -build {top::dbep %w \$::cnf(ftre) \$::cnf(ftrp)} -reopen 1"
#    $m tools mi stats  {Project Statistics}  -help {Open a toplevel preview window on the project statistics table (proj_v_stats)} -command "top::top proj_v_stats -title {Project Statistics}  -build {top::dbp %w -table proj_v_stats[priv::me] $::cnf(pst)} -reopen 1"
#    $m tools mi pgstat {Progeny Statistics}  -help {Open a toplevel preview window on the project progeny statistics table (proj_v_stats_pg)} -command "top::top proj_v_stats_pg -title {Project Progeny Statistics}  -build {top::dbp %w {-table proj_v_stats_pg[priv::me] $::cnf(pst)}} -reopen 1"
#    $m tools mi stats  {Project Permissions} -help {Open a toplevel preview window to view permissions of users on projects}       -command "top::top proj_v_auth  -title {Project Permissions} -build {top::dbp %w -table proj_v_auth $::cnf(pau)} -reopen 1"
#    $m tools mi ances  {Project Ancestors}   -help {Open a toplevel preview window to view the ancestors of the current project}   -command "top::top proj_v_rela  -title {Project Ancestors}   -build {top::dbp %w -table proj_v_rela_me $::cnf(rela)} -reopen 1"
#    $m tools mi come   {My Commissions} -s Comm -help {Open a preview window on the register showing my commissions earned vs/ my commissions/draws paid (commissions for current employee)} -command "top::top rg_v_cm_me -title {My Commissions}   -build {top::dbp %w -table rg_v_cm_me $::cnf(cmv)} -reopen 1"
#    $m tools mi reqs   {Requisitions} -s Reqs -help {Open a toplevel window for viewing/managing requisitions} -command "top::top reqs -title {Requisitions} -build {requis::build_reqs %w} -reopen 1"
#    $m tools sm lg -text {Ledger/Register Views} -help "Open a toplevel preview window showing a particular ledger view (lg_v_..._me) or register view (rg_v_..._me)."

#    foreach rec [sql::qlist {select tablename,title,help from wm.table_pub where tablename ~ '^[rl]g_v_.*_me$' and language = 'en' order by 2,1}] {
#        lassign $rec view title help
#        $m tools lg mi $view "$title ($view)" -help "Ledger View: $view\n$help" -command "top::top $view -title {Ledger: $view}   -build {top::dbp %w -table $view $::cnf(lgv)} -reopen 1"
#    }
#    gl::ar_agingp $m tools

    if {[base::priv_has 3 -priv projman]} {
        $m tools mi sep
        $m tools mi open {Reopen Project} -help {Set the status of a closed project back to open} -command "$w.e set status {open}; $w.e update"
    }
#    if {[base::priv_has 1 -priv commis]} {
#        $m tools mi sep
#        $m tools mi coml {Commission Register} -help {Open a preview window on the register showing commissions earned vs/ commissions/draws paid} -command "top::top rg_v_cm -title {Commission Register}   -build {top::dbp %w -table rg_v_cm $::cnf(cmv)} -reopen 1"
#        $m tools mi comm {Project Commissions} -help {Open a toplevel window for entering/viewing/editing commission formulae} -command "top::top comm -title {Project Commissions:} -build {top::dbep %w \$::cnf(cmse) \$::cnf(cmsp)} -reopen 1"
#        gl::hand_cms $m tools
#    }

    $m mb rept Reports -under 0 -help {Report views pertaining to projects}
#    $m rept mi compo {Child Metrics}      -under 6 -command "proj::chmet $w.e" -help {Show revenues, costs, profits, etc. on the children of the current project}
#    $m rept mi jobsu {Job Summary}        -under 0 -command {proj::jobsum}     -help {Show open or closed jobs within a period, and how much revenues are attributable to each job in that period}
#    $m rept mi jobsuf {Job Summary Full}        -under 5 -command {proj::jobsumfull}     -help {Show open or closed jobs within a period, organized by category and owners, and how much revenues are attributable to each job in that period}
#    $m rept mi compo {Over/Under Billing} -under 0 -command {proj::overund}    -help {Show a comparison of billings vs/ earned revenue on all top level jobs (immediate children of pcb projects and their progeny)}
#    $m rept mi compo {PC Revenues}        -under 0 -command {proj::compo}      -help {Show each project's expenses' contribution to percent-completion revenues (incurred while the project is open)}
#    $m rept mi compc {PC Offsets}         -under 0 -command {proj::compc}      -help {Show each projects' contribution to percent-completion offsets (incurred on project closing)}
#    $m rept mi uncmt {Uncompleted MTRs}  -under 0 -command "proj::unc_mtr $w.e"    -help {Show any MTR's that are not closed or void}
#    $m rept mi compc {Inactive Projects}  -under 0 -command {proj::inactiv}    -help {List open projects ordered by the date of the last transaction booked to the project}
#    if {[priv::haspriv limit -priv emplim] || [priv::haspriv limit -priv commis]} {
#        $m rept mi comsum {Commission Summary} -under 1 -command {proj::comsum} -help {Create a report showing commissions due for all people in the commission table}
#    }
#    $m rept mi prosp {Prospecting}       -under 0 -command {report_prosp}     -help {Show prospecting document statistics for a period}
#    $m rept mi mrep  {Materials Summary} -under 0 -command {report_mrep {m proje}}      -help {Create a materials summary report for this project's orders}
#    $m rept mi gsaq  {GSA Report}        -under 0 -command {proj::gsa_rep}    -help {Show line totals on orders marked with the gsa flag, according to the date of the first valid invoice booked to the order}

    top::add [eval dbe::dbe $w.e -pwidget $w.p $cfig(proje) -bg blue] proje
    pack $w.e -side top -fill both
    $w.e menu menu configure -under 0

    top::add [eval dbp::dbp $w.p -ewidget $w.e $cfig(projp)] projp
    pack $w.p -side top -fill both -expand yes
    $w.p menu menu configure -under 2
    return 1
}

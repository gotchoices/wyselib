# Support functions for basic wyseman schema
#------------------------------------------
#Copyright WyattERP: GNU GPL Ver 3; see: License in root of this package
package provide wyselib 0.20

#TODO:
#- 

namespace eval base {
    namespace export build priv_has priv_run priv_check priv_alarm priv_me user_eid user_name user_username menu_parm build_priv build_comm build_addr
    variable prc	;#cache of values from privilege table
    variable cfig
    set cfig(su)	{}
    set cfig(idfield)	id
    set cfig(nmfield)	std_name
    set cfig(unfield)	username
    set cfig(privtab)	base.priv_v
    set cfig(usertab)	base.ent_v_pub
    set cfig(addrtab)	.addr_v
    set cfig(commtab)	.comm_v
    set cfig(addrview)  {}
    set cfig(commview)  {}
    set cfig(priview)	{}
    set cfig(suffix)	{}
    
    set cfig(pref) {}		;#Preferences control array {tag title display_type user_edit}

    set cfig(ente) "base.ent_v -slaves {{priv p} {com p} {addr p}} $wyselib::dbebuts
        -dlr.pre base::ent_pre_dlr -adr.pre base::ent_pre_com -upr.pre base::ent_pre_com
    "
    set cfig(entp) "-selectmode extended $wyselib::dbpbuts -disp {id ent_type activ std_name username born_date ent_cmt}"

    set cfig(prive) "base.priv_v $wyselib::dbebuts -adr.pre {base::priv_pre_com %w add} -upr.pre {base::priv_pre_com %w upd} -dlr.pre {base::priv_pre_com %w del}"
    set cfig(privp) "$wyselib::dbpbuts -display {grantee std_name priv_level database priv_list}"

    set cfig(addre) "$wyselib::dbebuts -check {f {addr_spec country prime} r {city state}} -adr.pre base::addr_pre_add"
    set cfig(addrp) "$wyselib::dbpbuts -disp {addr_spec city state zip addr_cmt addr_ent comm_seq} -order {addr_ent addr_seq}"
    
    set cfig(comme) [concat $wyselib::dbebuts {
        -check {f {comm_spec comm_type}}  -adr.pre base::comm_pre_add\
        -m {conn	{Dial/Email}	{connect %w} -s {Connect -gmc {-exp 1} -bg orange} -help "Automatially dial a phone number, write to an email, browse a web address, etc. (your telephone extension must be specified in the application preferences for auto dialing to work)"}
    }]
    set cfig(commp) "-selectmode extended $wyselib::dbpbuts -disp {comm_type comm_spec comm_cmt comm_ent comm_seq} -order {comm_ent comm_seq}"

    set cfig(parme) "-table base.parm_v $wyselib::dbebuts -check {f {module parm type value}}"
    set cfig(parmp) "$wyselib::dbpbuts -disp {module parm type value cmt} -order {module parm} -load 1"
}

# Items common to add/update
#------------------------------------------
proc base::ent_pre_com {w} {
    if {![base::priv_check -pr entim]} {return 0}
    $w force ent_name ent_type
    if {[$w g ent_type] == {p}} {$w force fir_name gender}
    if {[$w g inside] == {t}} {$w request born_date tax_id}
    return ?
}

# Do before deleting the contact record
#------------------------------------------
proc base::ent_pre_dlr {w} {
    if {![base::priv_has super entim]} {return 0}
    if {[dia::ask {Are you sure you want to delete this entity:} 1 {Delete} Cancel] < 0} {return 0}
    return 1
}

# Do before adding an address record
#-------------------------------------------------
proc base::addr_pre_add {w} {
   variable cfig
   $w set addr_ent [eval $cfig(addrview)]
   return 1
}

# Do before adding an address record
#-------------------------------------------------
proc base::comm_pre_add {w} {
   variable cfig
   $w set comm_ent [eval $cfig(commview)]
   return 1
}

# Items common to privilege add/update
#------------------------------------------
proc base::priv_pre_com {w {func add}} {
    variable cfig
    if {[$w g grantee] == {}} {$w set grantee [eval $cfig(priview) g username]}
    lassign [sql::one "select cas_name, superv from empl.empl_v_pub where username = '[$w g grantee]'"] casual superv
#debug "priv_pre_com func add casual:$casual username:[$w g grantee]"
    priv::alarm "User [user::name] changing privs for $casual: $func [$w g priv]:[$w g level]\n" -subject "Permission change ($casual)" -idlist "$superv"
    return "[cdoc::log "Permission $func [$w g priv]:[$w g level]" [eval $cfig(priview) g id]];\n%q"
}


# Menu/builder: product types
#----------------------------------------------------
top::menu base parm {} {System Parameters} {Open a toplevel window for viewing/editing parameters used in various modules throughout the database.}
proc base::parm_build {w} {return [top::dbep $w $base::cfig(parme) $base::cfig(parmp)]}

# Build toplevel window to view and edit privledges
#------------------------------------------------------
proc base::build_priv {w args} {
   variable cfig
   foreach s {priview} {xswitchs $s args cfig($s)}
puts "view: $cfig(priview)"

   set m [$w menu w]
   $m mb tools -under 0 -help {Common helpful functions for this application}

   top::add [dbe::dbe $w.e -pwidget $w.p {*}$base::cfig(prive)] e
   top::add [dbp::dbp $w.p -ewidget $w.e {*}$base::cfig(privp) -min 100] p
   pack $w.e -side top -fill x
   pack $w.p -side top -fill both -expand yes

   return 1
}

# Build top level window for viewing and editing entity communications
#-------------------------------------------------------
proc base::build_addr {w args} {
   variable cfig
   foreach s {prefix addrview} {xswitchs $s args cfig($s)}
   
   set m [$w menu w]
   $m mb tools -under 0 -help {Common helpful functions for this application}

   top::add [dbe::dbe $w.e -pwidget $w.p {*}$cfig(prefix)$cfig(addrtab) {*}$base::cfig(addre)] e
   top::add [dbp::dbp $w.p -ewidget $w.e {*}$base::cfig(addrp) -min 100] p
   pack $w.e -side top -fill x
   pack $w.p -side top -fill both -expand yes

   return 1
}

# Build top level widnow for viewing and editing address and communications
#-------------------------------------------------------
proc base::build_comm {w args} {
   variable cfig

   foreach s {prefix commview} {xswitchs $s args cfig($s)}

   set m [$w menu w]
   $m mb tools -under 0 -help {Common helpful functions for this application}

   top::add [dbe::dbe $w.e -pwidget $w.p {*}$cfig(prefix)$cfig(commtab) {*}$base::cfig(comme)] e
   top::add [dbp::dbp $w.p -ewidget $w.e {*}$base::cfig(commp) -min 100] p
   pack $w.e -side top -fill x
   pack $w.p -side top -fill both -expand yes

   return 1
}


# Construct the main window for viewing/editing entities
#----------------------------------------------------
proc base::build {w} {
    variable cfig

    if {![eval base::priv_check -pr entim]} {return 0}
    set m [$w menu w]
    $m mb tools -under 0 -help {Common helpful functions for this application}
#    $m tools mi priv {Privileges} -under 0 -s Privs -help {Assign module permissions to a user} -command "top::top priv -title Privileges: -build {top::dbep %w \$base::cfig(prive) \$base::cfig(privp)} -par $w"
    $m tools mi priv {Privileges} -under 0 -s Privs -help {Assign module permissions to a user} -command "top::top priv -title Privileges: -build {base::build_priv %w -priview {m ente}} -par $w"
     $m tools mi cnm  {Contact Information} -under 0 -s Com -help {Toplevel window for viewing and editing communication information} -command "top::top com -title {Contact Information:} -build {base::build_comm %w -prefix base -commview {ents ente g id}} -reopen 1"
     $m tools mi adr {Entity Addresses} -under 0 -s Adr -help {Open a toplevel window for viewing/managing entity addresses} -command "top::top addr -title Addresses: -build {base::build_addr %w -prefix base -addrview {ents ente g id}} -reopen 1"
#    $m tools mi newu {Add as user} -under 0 -help {Register the current useroyee as a new user of the database} -command "base::create_user $w"
#    $m tools mi oldu {Drop as user} -under 0 -help {Remove the current useroyee from being a user of the database} -command "base::drop_user $w"

#    frame $w.u -bg blue
#    frame $w.ac
#    top::add [sizer::sizer $w.us -plus $w.u -orient v -size 3] usize
    
#    frame $w.ac.a -bg red
#    frame $w.ac.c -bg yellow
#    top::add [sizer::sizer $w.ac.as -plus $w.ac.a -orient h -size 3] asize

#    pack $w.u		-side left -fill both -exp 0
#    pack $w.us		-side left -fill y
#    pack $w.ac		-side left -fill both -exp 1
#    pack $w.ac.a	-side top  -fill both -exp 0
#    pack $w.ac.as	-side top  -fill x
#    pack $w.ac.c	-side top  -fill both -exp 1
    
    top::add [dbe::dbe $w.e -pwidget $w.p {*}$base::cfig(ente)] ente
    top::add [dbp::dbp $w.p -ewidget $w.e {*}$base::cfig(entp) -min 200] entp
    pack $w.e -side top -fill x
    pack $w.p -side top -fill both -expand yes

#    top::add [dbe::dbe $w.ac.a.e -pwidget $w.ac.a.p {*}$base::cfig(addre)] addre
#    top::add [dbp::dbp $w.ac.a.p -ewidget $w.ac.a.e {*}$base::cfig(addrp) -min 100] addrp
#    pack $w.ac.a.e -side top -fill x
#    pack $w.ac.a.p -side top -fill both -expand yes

#    top::add [dbe::dbe $w.ac.c.e -pwidget $w.ac.c.p {*}$base::cfig(comme)] comme
#    top::add [dbp::dbp $w.ac.c.p -ewidget $w.ac.c.e {*}$base::cfig(commp) -min 100] commp
#    pack $w.ac.c.e -side top -fill x
#    pack $w.ac.c.p -side top -fill both -expand yes
    return 1
}

# Stub for sitelib procedure to customize tablenames based on permissions
#------------------------------------------
proc base::priv_me {args} {return {}}

# Is the current user privileged at the limited level or above?
#------------------------------------------
proc base::priv_has {args} {
    variable cfig
    variable prc

    argform {level priv} args
    argnorm {{level 1} {privilege 2 priv}} args
    lassign "user [lib::cfig appname]" level priv
    foreach s {level priv} {xswitchs $s args $s}
#puts "priv_has: level:$level priv:$priv"
    if {![info exists prc(has.$priv.$level)]} {
        lassign [sql::one "select case when base.priv_has('$priv','$level') then 1 else 0 end;"] prc(has.$priv.$level)
    }
    if {[lcontain $cfig(su) [user_username]]} {return 1}	;#superuser
    return $prc(has.$priv.$level)
}

# Check for the minimum level of required permission.  On error, quit program
#------------------------------------------
proc base::priv_run {{level limit} args} {
    if {![eval priv_has $level $args]} {
        dia::err "Insufficient privileges ($level $args)"
        exit
    }
}

# Check for a level of permission and report any error to the user
#------------------------------------------
proc base::priv_check {args} {
    if {[eval priv_has $args]} {return 1}
    dia::err "Insufficient privilege level ($args)"
    return 0
}

# Return a list of usernames in a level for this application (or privilege)
#------------------------------------------
proc base::priv_llist {level {priv {}}} {
    variable cfig
    variable prc
    if {$priv == {}} {set priv [lib::cfig appname]}
#puts "base::priv_llist priv:$priv"
    if {![info exists prc(users.$priv.$level)]} {
        set prc(users.$priv.$level) [sql::qlist "select $cfig(unfield) from $cfig(usertab) where current and base.priv_role(username,'$priv','$level') order by 1"]
    }
#debug prc(users.$priv.$level)
    return $prc(users.$priv.$level)
}

# Send a message to the supervisors for this application
#------------------------------------------
proc base::priv_alarm {msg args} {
    variable cfig
#debug priv_alarm: args
    argform {level} args
    argnorm {{level 1} {privilege 1 priv} {idlist 2} {launch 2} {maillist 2 mlist} {description 2 ldesc} {editmsg 2} {subject 2}} args
    array set "level user priv [lib::cfig appname] editmsg 0"
    foreach s {level priv editmsg} {xswitchs $s args ca($s)}
    foreach s {idlist launch mlist ldesc subject} {set ca($s) [xswitchs $s args]}

    if {$ca(priv) != {}} {
        set ca(mlist) [concat $ca(mlist) [priv_llist $ca(level) $ca(priv)]]
    }
    if {$ca(idlist) != {}} {
        foreach rec [sql::qlist "select $cfig(unfield) from $cfig(usertab) where $cfig(idfield) in ([join $ca(idlist) ,])"] {
            lassign $rec username
            if {$username != {}} {lappend ca(mlist) $username}
        }
    }
    if {$ca(mlist) == {}} {
        error "Can't determine whom to mail to"
    }
#debug ca(idlist) ca(mlist)
    if {[llength $ca(mlist)] <= 0} {dia::warn "No recipients found to mail to"; return}
    if {$ca(subject) == {}} {set ca(subject) "[cap_first $ca(priv)] Exception:"}
    lib::mail_to [join $ca(mlist) ,] $msg -subject $ca(subject) -launch $ca(launch) -ldesc $ca(ldesc) -editmsg $ca(editmsg)
}

# Get information from database about current user
#------------------------------------------
proc base::user_init {args} {
    variable v
    variable cfig

    lassign [sql::one "select $cfig(idfield),current_user,$cfig(nmfield) from $cfig(usertab) where $cfig(unfield) = session_user" {}] v(eid) v(username) v(name)
#debug v(eid) v(username) v(name)
    if {$v(eid) == {}} {
        dia::err "Current user not found in entity database"
        exit 1
    }
    return 1
}

#Return information about current user
#------------------------------------------
proc base::user_eid {}		{if {![info exists base::v(eid)]}	user_init;	return $base::v(eid)}
proc base::user_name {}		{if {![info exists base::v(name)]}	user_init;	return $base::v(name)}
proc base::user_username {}	{if {![info exists base::v(username)]}	user_init;	return $base::v(username)}

if {[info commands locawyze] != {}} {locawyze base}

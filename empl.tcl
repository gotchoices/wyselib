# Support functions for the employee information manager
#------------------------------------------
#Copyright WyattERP: GNU GPL Ver 3; see: License in root of this package
package provide wyselib 0.20

#TODO:
#- 

namespace eval empl {
    namespace export
    variable cfig

    def cfig(labtpt) {{{title {} { } c} {pref_name {} { }} {ent_name}} {{addr {} {}}} {{city} {state {, }} {zip {  }} {country { }}}}
    def cfig(addtpt) {{{addr {} {} c}} {{city} {state {, }} {zip {  }} {country { }}}}
    def cfig(table) empl.empl_v
#    def cfig(table) empl.empl_v_sup

    set cfig(pref) {\
     -f {dmpl		ent	{Default Employer:}	empl::cfig(dmpl)	-def 1 -width 4 -just r -help {The entity ID of the employer to run as by default}}\
     -f {myext   ent     {Telephone Extension:}  ::cnf(myext)    -help {The extension number of your office phone} -width 4}\
    }

    set cfig(emple) [concat $wyselib::dbebuts {
        -slaves {{com p} {addr p} {docs p} {priv p} {keys p} {hold p} empl_orgchart payroll_emp_time payroll_emp_summ payroll_emp_whold}\
        -dlr.pre empl::pre_dlr -adr.pre empl::pre_adr -check {f {fir_name ent_name born_date hire_date pay_type pay_rate tax_id} r superv}
        -m {label	{Address Label}		{empl::prlab %w} -s {Lab} {Print a mailing label for this employee}}
        -m {dial    	{Dial}                  {empl::phone_dial %w %cnf(myext)} -hotkey {<Alt-k>} -s {Dial} -help "Dial the phone number for this person\nHot key: Alt-k"}
        -m {email	{Send Email}		{lib::email [com e g comm_spec]} -s {Email} -hotkey {C-m} -help {Send an email to this person}}
        -m {tmail	{Text Message}		{lib::email [com e g tmail] -text 1} -s {Text} -hotkey {C-t} -help {Send a message to this person's cell phone via text messaging}}
        -m {bos		{Load Supervisor}	{%w load "[%w get emplr] [%w get superv]"} -s {Bos} -help "Load the record for this employee's supervisor"}
        -m {dir		{Show Direct Reports}	{%w pwidget load -where "activ is true and superv = [%w get emple] "} -s {Dir} -help "Show the immediate subordinates of the current employee"}
        -m {sub		{Show All Subordinates}	{%w pwidget load -where "activ is true and [%w get emple] = any(supr_path)"} -s {Sub} -help "Show the all subordinates of the current employee"}
        -m {view	{View Picture}		{empl::view %w} -s {View -bg tan} {View a photo of this employee (the latest document with annotation: photo)}}
        -m {bge     	{Access Badge}          {empl::badge %w} -s {Badge} {Print Access Badge for selected employee}}
        -m {cores	{Write Letter}		{cdoc::cores [%w get emple] {grab_addr %w}} -s {Cores -gmc {-exp 1} -bg orange} -hotkey {C-l} -help "Write a letter and log it to the document history"}
    }]

    def cfig(emplp)	"-selectmode extended $wyselib::dbpbuts \
        -disp {emple emplr std_name current title role level superv supr_name supr_path gender born_date username} \
        -def {-where {{0.current tr}} -order std_name} \
    "
    set cfig(prive) {.priv_v -master {{m emple}}\
        -adr.pre {priv_pre_com %w add} -upr.pre {priv_pre_com %w upd} -dlr.pre {priv_pre_com %w del}\
        -m clr -m adr -m upr -m dlr -m prv -m rld -m nxt -m ldr\
    }

    set cfig(privp) { \
        -m clr -m def -m rld -m all -m prv -m nxt -m lby -m aex\
        -disp {empl_id priv alevel username casual comment}\
    }

    set cfig(keye) {empl_keys_v -master {{m emple}} \
        -adr.pre keys_pre_com -upr.pre keys_pre_com\
        -m clr -m adr -m upr -m dlr -m ldr\
    }

    set cfig(keyp) { \
        -m clr -m def -m rld -m all -m prv -m nxt -m lby -m aex\
        -disp {empl_id type kid code cmt empname}\
    }

    set cfig(holde) {empl_whold_v -master {{m emple}} \
        -check {f {proj acct amount}}\
        -m clr -m adr -m upr -m dlr -m ldr\
    }
    set cfig(holdp) { \
        -m clr -m def -m rld -m all -m prv -m nxt -m lby -m aex\
        -disp {acct acctname amount type pretax comment formal empl_id proj}\
    }

}

    
 

# Do before adding a new employee
#------------------------------------------
proc empl::pre_adr {w} {
    variable cfig
    if {![base::priv_check super]} {return 0}
    set mp $cfig(mplr[mytop $w])
    if {[$w g emplr] == {}} {
        $w s emplr $mp
    } elseif {[$w g emplr] != $mp} {	;#intending to add employee data for existing entity
        if {[dia::ask "Employee: [$w g std_name] already exists for employer: [$w g emplr].  Did you mean to also add as employee to employer: $mp?" 0 Yes Cancel] < 0} {return 0}
        $w s emplr $mp
    } elseif {[$w g emple] != {}} {	;#adding someone using an existing empl record as a template
        $w s ent_id {}			;#so start with blank key values
        $w s emple {}
    }
    return ?
}

# Do before updating an employee record
#------------------------------------------
proc empl::pre_upr {w} {
    variable cfig
    if {![base::priv_check]} {return 0}
    set t [mytop $w]
    if {[$w g emplr] == {}} {
        if {[dia::ask "Link existing personal entity: [$w g std_name] to organizational entity: $empl::cfig(mplr$t) as an employee?" 0 Yes Cancel] < 0} {return 0}
        $w emplr set $empl::cfig(mplr$t)
    }

#FIXME:
#    if {![base::riv_has super]} {
#        foreach i {emple surname givnames jobtitle country ssn bday hiredate termdate superv proxy status mstat allow wccode} {
#            if {[$w field $i modified]} {dia::err "Sorry, you don't have permission to change the field: [$w field $i cget title]"; return 0}
#        }
#    }
#    if {[$w field pay_rate modified]} {
#        base::priv_alarm "User [user::name] just changed payrate for: [$w get casual] to: [$w get payrate]\n" -subject "Pay rate change ([$w get casual])"
#    }

#    set chlist {}
#    foreach ftag {surname givnames jobtitle empltyp ssn hiredate superv proxy status mstat allow paytyp payrate} {
#        if {[$w get $ftag] != [$w last $ftag]} {
#            lappend chlist "[$w field $ftag cget -title] [$w last $ftag] -> [$w get $ftag]"
#        }
#    }
#    if {$chlist != {}} {return "[cdoc::log [join $chlist "\n"] [$w pk]];\n%q"}
    return ?
}

# Do before deleting the contact record
#------------------------------------------
proc empl::pre_dlr {w} {
    return [base::priv_check super]
}

# Items common to add/update of keys/security
#------------------------------------------
proc keys_pre_com {w} {
    $w force kid type
    if {[$w g type] == {locker}} {$w request code}
    return ?
}

# Print a label
#------------------------------------------
proc empl::prlab {w} {
    print::print addlab -init tmarg=0 -init lmarg=0 -command "labtpt \$empl::cfig(labtpt) $w"
}

#Try to view a photo of this person
#------------------------------------------
proc empl::view {w} {
    variable cfig
puts FIXME:
    if {[$w pk] == {}} return
    set doc_id [sql::one "select doc_id from empl_cdoc_v where cont_id = [$w pk] and annote = 'photo' order by crt_date desc limit 1"]
    if {$doc_id != {}} {cdoc::view $doc_id}
}

# Grab the current contact and return it in an array suitable for ledit
#----------------------------------------------------
proc empl::grab_addr {w} {
    variable cfig
puts FIXME:
#puts "Grab Address w:$w"
    set data {}
    set pref [$w get pref_name]
    set addr [labtpt $cfig(addtpt) $w]

    if {$pref == {}} {
        set salu "Dear Mr. [$w get surname]"
    } else {
        set salu "Dear $pref"
    }
    if {[set id [$w pk]] == {}} {dia::err {No contact loaded}; return {}}
    return [list [$w get cas_name] $addr $salu $id {} [com e get comm_spec]]
}


#Duplicate all records from one user to a second user
#----------------------------------------------------
proc clone_privs {w} {
    if {![base::priv_check user -priv privedit]} {return 0}

    set e [$w emple w]
    set tuser [$e get username]
    if {[scm::dia {Clone from what user:} dia_user username -dest fuser] < 0} return
debug fuser tuser
    if {[set res [dia::ask {Add Permissions:} 0 {All at Once} {One at a Time} Cancel]] < 0} return
    if {$res == 0} {set pr {no}} else {set pr {yes}}
    foreach rec [sql::qlist "select p.priv,p.level from base.priv_v p where p.grantee = '$fuser' and not exists (select * from base.priv where grantee = '$tuser' and priv = p.priv);"] {
        lassign $rec priv level
        priv e set priv $priv
        priv e set level $level
        priv e add -prompt $pr
#        if {![priv e add -prompt yes]} return  ;#doesn't allow us to skip a priv
    }
}

# Call an employee
# w:    window containing phone number
#----------------------------------------------------
proc empl::phone_dial {w ext} {
    if {$ext=={}} {dia::err "You must first register you extension in the preferences window and then restart the program"; return}
    if {[$w g emple] == {}} {dia::err "Please select a contact first"; return}
    set phone [com e g comm_spec]
    if {$phone == {}} {dia::brief "No phone number to dial"; return}
    ast::dial $phone
}

# Print a Door Access badge for employee
#-----------------------------------------------------
proc empl::badge {w} {
    if {[$w get emple] == {}} {dia::warn "You must first select and employee."; return 0}
    set wdir [lib::cfig workdir]
    foreach rec [sql::qlist "select emple, cas_name, empl_photo(emple) from empl.empl_v_pub where activt and emple = [$w get emple] and emplr = [$w get emplr] order by emple desc"] {
        lassign $rec empl_id name photo

# retrieve jpg from empl_cdoc_data
        if {"$photo" != {}} {
        set fname "$wdir/$name"
        puts "$fname"
        osdep::unsmash_data $photo ${fname}.jpg
        set file $name.jpg
#puts "file: $file"
        }
        system "cat /ati/etc/badge.txt | sed -e \"s/%%NAME%%/$name/g\" -e \"s/%%ID%%/$empl_id/g\" -e \"s/%%FNAME%%/$file/g\" > $wdir/badge.html"
#        system "wkhtmltopdf.sh [lib::cfig workdir]/badge.html [lib::cfig workdir]/badge.pdf"
#       system "xvfb-run -a -s \"-screen 0 640x480x16\" wkhtmltopdf --use-xserver --page-size A4 --quiet $wdir/badge.html  $wdir/badge.pdf"
#breb xvfb is required because the images are of inconsistent size and are defined by pixel size in badg.txt, to prevent 
# variation creeping in if used on a different system with different resolutin we use the the frame buffer to always have
# the same environment to build the image.
        system "xvfb-run -a -s \"-screen 0 640x480x16\" wkhtmltopdf --use-xserver --page-width 54 --page-height 85.6 -B 2 -L 2 -R 2 -T 2 --quiet $wdir/badge.html  $wdir/badge.pdf"
    }
#    system "evince $wdir/badge.pdf &"
    system "lpr -P ID1 -o fit-to-page $wdir/badge.pdf"
}

# Produce an organizational chart for the specified employee
#----------------------------------------------------
report::report empl::orgchart {ec} {
    proc org {sup {pre {}}} {           ;#for recursive calls to sub-orgs
        set dat {}
        foreach rec [sql::qlist "select emple,std_name,role from empl.empl_v_pub where current = true and superv = $sup and superv != emple order by 2"] {
            lassign $rec empl_id formal title
            append dat "[format "%s%-30.30s %s\n" $pre $formal $title]"
            append dat [org $empl_id "${pre}|   "]
        }
        return $dat
    }
    set empl_id [eval $ec get emple]
    lassign [sql::one "select emple,std_name,role from empl.empl_v_pub where emple = [sql::bton $empl_id]"] eid formal jobtitle
    if {$eid == {}} return
    set dat "[lib::cfig comname] Organizational Chart:\nPrinted: [date::date]\n\n"
    append dat "[format "%-30.30s %-40.40s\n" $formal $jobtitle]"
    append dat [org $empl_id {    }]
    return $dat
}

#Try to view a photo of this person
#------------------------------------------
proc empl::view {w} {
    global cnf
    if {[$w pk] == {}} return
    set doc_id [sql::one "select doc_id from empl_cdoc_v where cont_id = [$w g id] and annote = 'photo' order by crt_date desc limit 1"]
    if {$doc_id != {}} {cdoc::view $doc_id}
}


# Construct the main window
#----------------------------------------------------
proc empl::build_empl {w {table {}}} {
    global cnf
    variable cfig

    eval pref::init -mod empl $cfig(pref)
    set m [$w menu w]
    $m mb tools -under 0 -help {Common helpful functions for this application}
    $m tools mi cnm  {Contact Information} -under 0 -s Com -help {Toplevel window for viewing and editing communication information} -command "top::top com -title {Contact Information:} -build {base::build_comm %w -prefix empl -commview {m emple g emple}} -reopen 1"
    $m tools mi chart  {Organization Chart} -under 0 -s Org -help {Show the chain of command under the current employee} -command {empl::orgchart {m emple}} -before 1
    $m tools mi adr {Entity Addresses} -under 0 -s Adr -help {Open a toplevel window for viewing/managing entity addresses} -command "top::top addr -title Addresses: -build {base::build_addr %w -prefix empl -addrview {m emple g emple}} -reopen 1"
    $m tools mi docs {Document Window} -under 0 -s Doc -help {Open a toplevel window for viewing/managing contact documents} -command "top::top docs -title Documents: -build {cdoc::cdoc %w} -reopen 1"
    $m tools mi grps {Group Window} -under 0 -s Group -help {Open a toplevel window for managing contact groups} -command "top::top group -title Groups: -build {cgroup::cgroup %w empl {m emplp} -newsch empl.empl} -reopen 1"

    $m tools mi sep
    $m tools mi priv {Privileges} -under 0 -s Privs -help {Allows assigning of module permissions to a user} -command "top::top priv -title Privileges: -build {base::build_priv %w} -reopen 1"

#FIXME:
    if {[base::priv_check limit -priv payroll]} {
        $m tools mi sep
        $m tools mi hold {Edit Withholdings} -under 5 -s Hold -help {Allows entering and editing of regular withholding amounts for each employee} -command "top::top hold -title {Employee Withholdings:} -build {top::dbep %w \$empl::cfig(holde) \$empl::cfig(holdp)} -reopen 1"
        $m tools mi payr {Payroll Module} -under 4 -s Pay -help {Launch the payroll window} -command "top::top pay -title Payroll: -build {payroll::payroll %w} -reopen 1"
        $m tools mi oldu {Clone User} -under 0 -help {Make privileges for the current user similar to another user you will specify} -command "clone_privs $w"
    }
    if {[base::priv_has 1 -priv emplkeys]} {
        $m tools mi sep
        $m tools mi keys {Edit Keys} -under 5 -s Keys -help {Allows entering and editing of key allocations (building keys, keycards, lockers, etc) for each employee} -command "top::top keys -title {Key Allocations:} -build {top::dbep %w \$empl::cfig(keye) \$empl::cfig(keyp)} -reopen 1"
    }

    $m mb rept Report -under 0 -help {Reports related to emplim}
    $m rept mi time {Vacation Report} -under 0 -command {payroll::emp_vac {m emple}}

    $m s dew::dew mplr ent {Employer:} -width 4 -just r -textv empl::cfig(mplr$w) -init $empl::cfig(dmpl) -spf scm -data mplr -help {The employer to consider employees for}

    if {$table == {}} {set table $cnf(table)}
    top::add [dbe::dbe $w.e -pwidget $w.p $table {*}$cfig(emple) -bg blue] emple
    $w.e menu menu configure -under 1
    top::add [eval dbp::dbp $w.p -ewidget $w.e $cfig(emplp)] emplp
    $w.p menu menu configure -under 2

    pack $w.e -side top -fill both
    pack $w.p -side top -fill both -expand yes

    cdoc::logmenu $w.e
    cdoc::logmenu $w.p
    return 1
}

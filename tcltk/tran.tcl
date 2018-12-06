# Create a GUI for entering/editing transaction journal entries
#Copyright WyattERP, all other rights reserved
package provide wyselib 0.20

#TODO:
#X- Allow to put conjugated account code in a single field and have the GUI split it into fields
#X- Allow to enter the offset account for non-split entries
#- Show the whole transaction in a dbp as it is entered
#- Allow to extend transaction (new hdr with new tr_seq) for existing locked headers
#- Disallow changes in closed periods (respect closed date)
#- 

namespace eval tran {
    namespace export tran_menu
    variable cfig

}

# Before adding a transaction item
#------------------------------------------
proc tran::pre_com {w} {
    if {[$w g debit] == {} && [$w g credit] == {}} {$w force amount}
    if {[$w g proj] == {} && [$w g acct] == {}} {$w force coding}
    $w force tr_date descr
    return ?
}

# Before adding a transaction item
#------------------------------------------
proc tran::pre_adr {w} {
    return [pre_com $w]
}

# Before updating a transaction item
#------------------------------------------
proc tran::pre_upr {w} {
    return [pre_com $w]
}

# Create a balancing debit/credit for the current transaction
#------------------------------------------
proc tran::balance {w} {
#puts "balance w:$w pk:[$w pk] keywhere:[$w keywhere] table:[$w cget table]"
    lassign [$w pk] id seq
    lassign [sql::one "select sum(-amount) from [$w cget table] where tr_id = $id and tr_seq = $seq"] amount
    $w field amount set $amount
    focus [$w field cmt entry w]
}

# Popup for inputting type, project, acct, category separately
#------------------------------------------
proc tran::coding {w} {
    set uw ".dia[translit . _ $w]"
    set vals [$w get]
    lassign [split $vals .] proj acct cat
    set ptyp [string range $proj 0 0]
    set proj [string range $proj 1 end]
    set parr [list \
        -f "ptyp ent 2 {1 1} {Type:}	 -ini {$ptyp} -just r -spf scm -data ptype" \
        -f "proj ent 6 {1 2} {Project:}  -ini {$proj} -just r -spf mdew -data {proj::lookup %w ptyp proj}" \
        -f "acct ent 6 {1 3} {Account:}  -ini {$acct} -just r -spf scm -data acct" \
        -f "cat  ent 6 {1 4} {Category:} -ini {$cat}  -just r -spf scm -data cat" \
    ]
    if {[eval dia::dia $uw -but \{OK Cancel\} -def 0 -message \{Edit positioning parameters:\} -entry mdew::mdew -dest res -pre 0 $parr] < 0} return
#debug res
    array set r $res
    $w set [join [string trim "$r(ptyp)$r(proj) $r(acct) $r(cat)"] .]
}

# Create a menu item to launch the hand entry journal
#----------------------------------------------------
proc tran::tran_menu {m menu tag module title} {
    $m $menu mi $tag $title \
        -help "Open a toplevel window for creating/editing transactions in the $title" \
        -command "top::top tran_$tag -title $title -reopen 1 -build {tran::tran_build %w $module}"
}

# Create a GUI for creating/editing journal entries
#------------------------------------------
proc tran::tran_build {w args} {
    variable cfig

    argform {module} args
    argnorm {{module 1} {journal 1}} args
    array set cfig "module$w acct journal$w tj_v"
    foreach s {module journal} {xswitchs $s args cfig($s$w)}
#    foreach s {x y z} {set cfig($s$w) [xswitchs $s args]}

    if {![eval base::priv_check]} {return 0}
    set cfig(table$w) "$cfig(module$w).$cfig(journal$w)"
    set m [$w menu w]
    $m mb tools -under 0 -help {Common helpful functions for this application}
#    $m tools mi priv {Privileges} -under 0 -s Privs -help {Assign module permissions to a user} -command "top::top priv -title Privileges: -build {top::dbep %w \$base::cfig(prive) \$base::cfig(privp)} -par $w"
    
    top::add [dbe::dbe $w.e -pwidget $w.p -table $cfig(table$w) {*}$wyselib::dbebuts -adr.pre tran::pre_adr -upr.pre tran::pre_upr \
        -m {new  {New Transaction}	-command {%w set tr_id {}; %w add} -s {New} -help {Clear the transaction ID field and then execute Add.  This will enter the data into a newly created transaction block.}}\
        -m {post {Post Transaction}	-command {%w set posted {t}; %w update} -s {Post} -help {Make the current transaction active in applicable accounting ledgers}}\
        -m {upst {Unpost Transaction}	-command {%w set posted {f}; %w update} -help {Make the current transaction so it does not have an effect in any accounting ledger}}\
        -m {bal  {Balancing Entry}	-command {tran::balance %w} -s {Balance} -help {Prepare an entry which will balance the current transaction block}}\
    ]
    
    top::add [dbp::dbp $w.p -ewidget $w.e {*}$wyselib::dbpbuts \
        -m dlr -m upr -update {descr cmt posted coding date amount}\
        -display {item_key tr_date posted descr cmt coding recon debit credit balance} \
        -order {tr_date tr_id tr_seq item} -see end \
    ]

    pack $w.e -side top -fill x
    pack $w.p -side top -fill both -expand yes
    return 1
}

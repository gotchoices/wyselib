# Support functions for basic wyseman accounting modules
#------------------------------------------
#Copyright WyattERP, all other rights reserved
package provide wyselib 0.10

#TODO:
#- 

namespace eval acct {
    namespace export cat_menu acct_menu meth_menu clos_menu
    variable cfig
    
    set cfig(accte) [concat -table acct.acct_v $wyselib::dbebuts {
        -check {f {acct_type acct_name} r acct_id} \
        -m {sublgr	{Show Sub-ledger}	{m lgr load -where "acct = [%w pk]"} -s {Show} -help "View the subledger (in the main window) for the currently loaded account"}
    }]
    set cfig(acctp) "$wyselib::dbpbuts -disp {numb code type iname descr container level fpath} -order fpath -load 1"

    set cfig(cate) "-table acct.cat_v $wyselib::dbebuts -check {f {cat_id cat_code cat_name}}"
    set cfig(catp) "$wyselib::dbpbuts -disp {numb code name descr} -order numb -load 1"

    set cfig(close) "-table acct.close_v $wyselib::dbebuts -check {f v_date}"
    set cfig(closp) "$wyselib::dbpbuts -disp {module v_date cmt} -order v_date -load 1 -m upr -update {v_date}"

    set cfig(methe) "-table acct.meth_v $wyselib::dbebuts -check {f {meth_code meth_name}}"
    set cfig(methp) "$wyselib::dbpbuts -disp {code name descr} -order name -load 1"
    set cfig(mmape) "-table acct.mmap_v $wyselib::dbebuts -check {f {book_acct meth_acct}}"
    set cfig(mmapp) "$wyselib::dbpbuts -disp {meth book_acct ba_name meth_acct ma_name cmt} -order {meth book_acct}"
}

# Menu/builder: Accounts
#----------------------------------------------------
top::menu acct acct Acct {Standard Accounts} {Open a toplevel window for viewing/editing standard accounts}
proc acct::acct_build {w} {return [top::dbep $w $acct::cfig(accte) $acct::cfig(acctp)]}

# Menu/builder: Closing dates
#----------------------------------------------------
top::menu acct clos {} {Closing Dates} {Open a toplevel window for viewing/editing period closing dates}
proc acct::clos_build {w} {return [top::dbep $w $acct::cfig(close) $acct::cfig(closp)]}

# Menu/builder: Transaction Categories
#----------------------------------------------------
top::menu acct cat Cats {Transaction Categories} {Open a toplevel window for viewing/editing defined transaction categories}
proc acct::cat_build {w} {return [top::dbep $w $acct::cfig(cate) $acct::cfig(catp)]}

# Menu/builder: Accounting methods
#----------------------------------------------------
top::menu acct meth {} {Accounting Methods} {Open a toplevel window for viewing/editing defined accounting methods}
proc acct::meth_build {w} {
    variable cfig

    frame $w.me -bg blue			;#methods
    frame $w.mm -bg violet			;#account mappings
    top::add [sizer::sizer $w.sz -plus $w.me -minus $w.mm -orient h -size 3] size
    
    top::add [eval dbe::dbe $w.me.e -pwidget $w.me.p $cfig(methe) -slaves $w.mm.p] methe
    top::add [eval dbp::dbp $w.me.p -ewidget $w.me.e $cfig(methp)] methp
    top::add [eval dbe::dbe $w.mm.e -pwidget $w.mm.p $cfig(mmape) -master $w.me.e] mmape
    top::add [eval dbp::dbp $w.mm.p -ewidget $w.mm.e $cfig(mmapp)] mmapp

    pack $w.me		-side top	-fill both
    pack $w.sz		-side top	-fill x
    pack $w.mm		-side top	-fill both -exp yes
    pack $w.me.e $w.mm.e -side top -fill both
    pack $w.me.p $w.mm.p -side top -fill both -expand yes
#    $w.me.e menu menu configure -under 0
#    $w.me.p menu menu configure -under 2
    return 1
}

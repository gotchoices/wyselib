#This file is automatically generated by wmmkpkg.

package ifneeded wyselib 0.20 [list set wyselib_library $dir/tcltk]\n[list source [file join $dir tcltk init.tcl]]\n[list tclPkgSetup $dir/tcltk wyselib 0.20 {
    {acct.tcl	source {::acct::cat_menu ::acct::acct_menu ::acct::meth_menu ::acct::clos_menu }}
    {base.tcl	source {::base::build ::base::priv_has ::base::priv_run ::base::priv_check ::base::priv_alarm ::base::priv_me ::base::user_eid ::base::user_name ::base::user_username ::base::menu_parm ::base::build_priv ::base::build_comm ::base::build_addr ::base::build_parm }}
    {empl.tcl	source {}}
    {pdoc.tcl	source {::pdoc::pdoc_menu ::pdoc::open_build ::pdoc::logmenu ::pdoc::new }}
    {prod.tcl	source {::prod::build ::prod::proc_build ::prod::edit_build ::prod::parm_edit ::prod::oper_menu ::prod::type_menu ::prod::unit_menu ::prod::dtyp_menu }}
    {proj.tcl	source {::proj::where_fam ::proj::ptyp_menu ::proj::proj_menu }}
    {tran.tcl	source {::tran::tran_menu }}
}]

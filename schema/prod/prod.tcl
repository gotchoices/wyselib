# Variables for production module
#----------------------------------------------------------------

namespace eval prod {
    def prod_pk		{base}
    def prod_v_in	{type_r name curr units descr}
    def prod_v_up	{type_r curr units descr}
    def prod_j_se	[concat $prod_pk maxv $prod_v_in]
    def prod_se		[concat $prod_j_se $glob::stampfn]
    
    def vers_pk		{base_r rev}
    def vers_v_iu	{spec change bom}
    def vers_j_se	[concat rev $vers_v_iu]
    def vers_se		[concat $vers_j_se base_r $glob::stampfn]
    def vers_prod_se	[concat $prod_j_se $vers_j_se locked current latest]
    
    def parm_pk		{base_rr rev_r var}
    def parm_v_iu	[concat $parm_pk ptyp units def descr]
    def parm_se		[concat $parm_v_iu pos $glob::stampfn]
    
    def sval_pk		{base_rrr rev_rr var_r ptyp_r}
    def sval_v_iu	[concat $sval_pk pos ptyp units descr]
    def sval_se		[concat $sval_v_iu $glob::stampfn]
}

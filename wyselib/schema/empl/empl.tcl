# Variables for empl module
#---------------------------------------------------

namespace eval empl {
    def empl_local	{}
    def empl_local_up	{}
    def empl_pk		{emplr emple}
    def empl_v_up	{empl_type stand empl_cmt superv hire_date term_date pay_type pay_rate allow ins_code}
    def empl_v_in	[concat $empl_pk [lremove $empl_v_up term_date]]
    def empl_se		[concat $empl_pk $empl_v_up $glob::stampfn]
    def ent_se		[concat $base::ent_pk $base::ent_v_in std_name frm_name cas_name]
    def ent_v_in	$base::ent_v_in
    def ent_v_up	[lremove $base::ent_v_up empl_type username]
    def empl_v_se	[concat $ent_se $empl_se supr_name prox_name current level ind_name birthday hour_rate norm_rate org mem role supr_path full_path mplr_name]
    def empl_v_pub_se	{emplr emple title pref_name ent_name fir_name role superv supr_name proxy prox_name username std_name cas_name current level birthday hire_date supr_path full_path}
    def empl_v_pub_up	{proxy}
    def empl_v_sup_se	[lremove $empl_v_se bank]
    def empl_v_sup_up	{pref_name role stand empl_cmt proxy superv term_date pay_type pay_rate}
    def addr_pk         {addr_ent addr_seq}
    def addr_v_in       {addr_ent addr_spec city state zip country addr_cmt prime status}
    def addr_v_up       [lremove $addr_v_in addr_ent]
    def addr_se         [concat $addr_pk $addr_v_up $glob::stampfn] 
    def comm_pk         {comm_ent comm_seq}
    def comm_v_in       {comm_ent comm_type comm_spec comm_cmt comm_label status}
    def comm_v_up       [lremove $comm_v_in comm_ent]
    def comm_se         [concat $comm_pk $comm_v_up $glob::stampfn]
    def local_wmd	{}
}


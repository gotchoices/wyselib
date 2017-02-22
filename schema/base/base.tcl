# Variables for the base namesapce
#--------------------------------------------------------
require ../common.tcl ../audit.tcl ../glob.tcl

namespace eval base {
    def ent_pk          {id}
    def ent_v_in        {ent_name ent_type ent_cmt fir_name mid_name pref_name title gender marital born_date username database activ inside country tax_id bank proxy}
    def ent_v_up        "$ent_v_in"
    def ent_se          [concat $ent_pk $ent_v_in $glob::stampfn]
    def ent_v_se        [concat $ent_se std_name frm_name cas_name]
    def ent_local       {}
    def ent_audit       "$ent_v_in"
    def ent_v_pub_se    [concat id std_name ent_type username activ inside $glob::stampfn]
    def ent_entmin      {100}
    def ent_insmin      {1000}
    def ent_outmin      {10000}
    def ent_link_pk     {org mem}
    def ent_link_v_in   [concat $ent_link_pk role]
    def ent_link_v_up   {role}
    def ent_link_se     [concat $ent_link_v_in supr_path $glob::stampfn]
}

# Variables for the base namesapce
#--------------------------------------------------------
require ../common.tcl ../audit.tcl ../glob.tcl

namespace eval base {
    def ent_pk          {id}
    def ent_v_in        {ent_name ent_type ent_cmt fir_name mid_name pref_name title gender marital born_date username ent_inact country tax_id bank proxy}
    def ent_v_up        [lremove "$ent_v_in" ent_type]
    def ent_se          [concat $ent_pk ent_num conn_pub $ent_v_in $glob::stampfn]
    def ent_v_se        [concat $ent_se std_name frm_name giv_name cas_name]
    def ent_local       {}
    def ent_audit       "$ent_v_in"
    def ent_v_pub_se    [concat id std_name ent_type ent_num username ent_inact $glob::stampfn]
    def ent_rolmin      {1}
    def ent_grpmin      {100}
    def ent_orgmin      {500}
    def ent_permin      {1000}
    def ent_link_pk     {org mem}
    def ent_link_v_in   [concat $ent_link_pk role]
    def ent_link_v_up   {role}
    def ent_link_se     [concat $ent_link_v_in supr_path $glob::stampfn]
    
    proc group_roles {defs deps} {
        foreach {role groups} $defs {
            set deps [concat {base.priv base.pop_role(text)} $deps]
            set grlist {}; if {$groups != {}} {
              set grlist "\"[join $groups {","}]\""
            }
            foreach sr $groups {		;# if a role contains another role, note the dependency
                lassign [split $sr _] n r
                if {$r == {}} {lappend deps base_role_$n}
            }
        #puts "base_role_$role deps:$deps grlist:$grlist"
            other base_role_$role $deps \
                "select wm.create_role('$role', '{$grlist}'); select base.pop_role('$role');" \
                "drop role if exists $role;"
        }
    }
}

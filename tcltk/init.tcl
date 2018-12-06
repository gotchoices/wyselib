# Run when this library is first required
#------------------------------------------
#Copyright WyattERP, all other rights reserved
package provide wyselib 0.20
package require wylib

#TODO:
#- Move dew commands below to procedure calls
#- 
dew::scm cat	{-eval {sql::qlist "select numb,code,name,descr from acct.cat_v order by numb"} -f numb -f code -f name -f descr -token code -tag scm_cat}
dew::scm acct_acct	{-eval {sql::qlist "select numb,code,iname from acct.acct_v order by idx"} -f id -f code -f name -token code -tag scm_acct}
dew::scm proj_proj	{-eval {sql::qlist "select code,iname from acct.proj_v order by idx"} -f code -f name -token code -tag scm_proj}
dew::scm ptype	{-eval {sql::qlist "select code,name,descr from acct.proj_type order by type"} -f code -f name -f descr -token code -tag scm_ptype}
dew::scm mplr	{-eval {sql::qlist "select id,std_name from base.ent_v_pub where ent_type = 'o' and inside order by 2"} -f id -f name -token id -tag scm_mplr}
dew::scm empl_empl	{-eval {sql::qlist "select emple,std_name from empl.empl_v_pub where current order by 2"} -f id -f name -token id -tag scm_empl}
dew::scm base	{-eval {sql::qlist "select base,descr,units from prod.prod order by 1"} -f base -f descr -f units -token base -tag scm_base}
dew::scm oper	{-eval {sql::qlist "select oper,descr from prod.oper order by 1"} -f oper -f descr -token oper -tag scm_oper}
dew::scm country {-eval {sql::qlist "select code,com_name from base.country order by 1"} -f code -f com_name -token code -tag scm_country}
dew::scm username {-eval {sql::qlist "select emple,username,std_name from empl.empl_v order by 3"} -f emple -f username -f std_name -token username -tag scm_username}
dew::scm certification {-eval {sql::qlist "select cid,title from empl.certs_v where status order by 2"} -f cid -f title -token cid -tag scm_certs}

# Global helper shortcuts
#------------------------------------------
namespace eval wyselib {
    set dbebuts		{-m clr -m adr -m upr -m dlr -m prv -m rld -m nxt -m ldr}		;#standard buttons for dbe
    set dbpbuts		{-m clr -m rld -m def -m all -m prv -m sel -m nxt -m lby -m aex}	;#standard buttons for dbp
}

# Standard scrolled menu functions
#------------------------------------------
namespace eval dew {
}

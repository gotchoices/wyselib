drop function if exists base.ent_audit_f(int);
drop view if exists base.ent_audit_v;

create view base.ent_audit_v as (
    select a.ent_id
  , a.a_seq
  , a.a_date
  , a.a_by
  , a.a_action
  , a.a_column
  , a.a_value
  , coalesce(p.a_date, (select crt_date from base.ent where ent_id = a.ent_id))		as p_date
  
  from		base.ent_audit		a
  left join	base.ent_audit		p on p.ent_id = a.ent_id and p.a_seq + 1 = a.a_seq
);

create function base.ent_audit_f(eid int) returns setof base.ent_audit_v language plpgsql as $$
    declare
        arec	base.ent_audit_v;
        trec	base.ent;
        c	varchar;
        cd	timestamp(0);
        tv	varchar;
    begin
        select into trec * from base.ent where ent_id = eid;
        arec.ent_id := eid;
        arec.a_seq := null;
        arec.a_date := current_timestamp;
        arec.a_by := trec.crt_by;
        arec.a_action := null;
        arec.a_column := null;
        arec.a_value := null;
        cd := trec.crt_date;
--        select into arec ent_id, null as a_seq, current_timestamp as a_date, crt_by as a_by, null as a_action, 
--            null as a_column, null as a_value, crt_date as p_date from base.ent where ent_id = eid;
        foreach c in array array['ent_name', 'ent_type', 'ent_cmt', 'fir_name', 'mid_name', 'pref_name', 'title', 'gender', 'marital', 'born_date', 'username', 'database', 'activ', 'inside', 'country', 'tax_id', 'bank'] loop
            arec.p_date := coalesce((select max(a_date) from base.ent_audit where a_column = c), cd);
            arec.a_column := c;
--            execute 'select trec.' || c || ';' into arec.a_value;
--            execute 'select $1;'into arec.a_value using 'trec.' || c;
            execute 'select ($1).' || c || '::varchar;' into arec.a_value using trec;
            return next arec;
        end loop;
        return;
    end;
$$;

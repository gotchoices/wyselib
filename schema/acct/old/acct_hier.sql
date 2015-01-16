-- Test recursive query on acct table
-- Cycle is supposed to stop infinite iteration if there is a loop in the account hierarchy

with acct_idxs as (
  with recursive acct_path(acct_id, depth, path, cycle) as (
      select	a.acct_id
          ,	1
          ,	array[a.acct_id]
          ,	false
      from	acct.acct a where par is null
  union all
      select	a.acct_id
          ,	ap.depth + 1
          ,	path || a.acct_id
          ,	a.acct_id = any(path)
      from	acct.acct	a 
      join	acct_path	ap on a.par = ap.acct_id and not cycle
  ) 
  select acct_id
    ,	ac.depth
    ,	ac.path
    ,	row_number() over (order by ac.path) as idx
    from	acct_path	ac
  )

select	a.acct_id
    ,	a.acct_type
    ,	a.acct_name
    ,	a.container
    ,	a.par
    ,	ai.depth
    ,	ai.path						as fpath
    ,	ai.path[1:array_upper(ai.path,1)-1]		as ppath
    ,	ai.idx
    ,	(select max(idx) from acct_idxs where path @> ai.path)	as mxc
    
from	acct.acct	a
join	acct_idxs	ai on ai.acct_id = a.acct_id
order by ai.path;

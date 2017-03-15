# Macros for creating a Transaction Journal for a specified subsystem
#------------------------------------------
#Copyright WyattERP: GNU GPL Ver 3; see: License in root of this package
#TODO:
#X-   Practice rapid entry
#X-   Which has precidence?  credit/debit or amount, separate code fields or coding
#X-   Try posting a record
#X-   Try unposting a record
#X-   Allow to update a posted record if the period is open, but not insert new items or update the amounts or change the dates
#X- Make unified view for header/items
#X- Implement GUI for editing journal entries
#X- Implement hot-keys for rapid data entry
#X- Can only delete un-posted entries
#- Check for unposted entries when moving up close date
#- Can only have un-posted entries in open periods
#- Closing function for each module?
#- 

namespace eval tran {
    def tj_hdr_pk	{tr_id tr_seq}
    def tj_hdr_iu	{tr_date descr posted}
    def tj_hdr_tiu	[concat $tj_hdr_pk $tj_hdr_iu $glob::stampfn]
    def tj_hdr_v_se	$tj_hdr_iu
    def tj_itm_pk	{id seq item}
    def tj_itm_iu	{cmt proj acct cat amount recon}
    def tj_itm_tiu	[concat $tj_itm_pk $tj_itm_iu]
    def tj_itm_v_se	$tj_itm_iu

  set db_objects {
    #sequence %S.tj_id {%S} {minvalue %M}		;#if using a sequence, see below in hdr_tf_pk
  
    # A dummy table containing only the tr_id for the sole purpose of getting referential integrity to work
    # on foreign key references intended to point to a series of sequential transaction blocks
    #----------------------------------------------------------------
    table %S.tj_tgr {%S} {tgrp int primary key}
    
    table %S.tj_hdr {%S.tj_tgr base.curr_eid()} {
        tr_id		int		references %S.tj_tgr on update cascade
      , tr_seq		int		default 0
      , primary key (tr_id, tr_seq)
      , tr_date		date		not null default current_date
      , descr		varchar
      , posted		boolean		not null default 'f'
        subst($glob::stamps)
    }
    index {} %S.tj_hdr tr_date

    tabtext %S.tj_hdr   {Journal Header} 	{Contains an entry for each balanced set of debits and credits grouped together on a single date to describe a transaction} [concat {
        {tr_id		{Trans ID}		{Each transaction is a assigned a unique, sequential ID number}}
        {tr_seq		{Sequence}		{When a transaction is first entered, it has a sequence number of 0.  If later adjusting transactions are entered linked to the same transaction ID number, they will be assigned a new header record with a larger sequence number so they can have a different date, comment and posting status.}}
        {tr_date	{Date}			{The date for which this transaction block will appear in the ledger}}
        {descr		{Description}		{A comment describing the transaction as a group (the purpose of all the debits and the credits together)}}
        {posted		{Posted}		{A boolean (yes/no) status indicating if the transaction will appear in the general ledger and other reporting ledgers}}
    } $glob::stampt]
    
    # Before inserting a header record
    #----------------------------------------------------------------
    function %S.tj_hdr_tf_pk() {%S.tj_hdr acct.close(varchar)} {
      returns trigger security definer language plpgsql as $$
        begin
            if new.tr_id is null then
--              new.tr_id  := nextval('%S.tj_id');		-- enable for using sequence (also include S.tj_id in dependencies for this function)
                select into new.tr_id coalesce(max(tr_id)+1,%M) from %S.tj_hdr;	-- simpler than a sequence but could possibly produce a (generally harmless) collision once in a while
                new.tr_seq := 0;
            elseif new.tr_seq is null then
                select into new.tr_seq coalesce(max(tr_seq)+1,0) from %S.tj_hdr where tr_id = new.tr_id;
            end if;
            if new.posted and session_user != 'dbadmin()' and new.tr_date <= acct.close('%P') then	-- in case someone tries to write a posted entry in a closed period
                raise exception '!acct.close.DCP % % %', '%S', new.tr_id, new.tr_seq;
            end if;
            if not exists (select * from %S.tj_tgr where tgrp = new.tr_id) then				-- create a group record if it doesn't already exist
                insert into %S.tj_tgr (tgrp) values (new.tr_id);
            end if;
            return new;
        end;
    $$;}
    trigger %S_tj_hdr_tr_pk {} {before insert on %S.tj_hdr for each row execute procedure %S.tj_hdr_tf_pk();}
    
    # After deleting a header record
    #----------------------------------------------------------------
    function %S.tj_hdr_tf_ad() {%S.tj_hdr %S.tj_tgr} {
      returns trigger security definer language plpgsql as $$
        begin
            if not exists (select * from %S.tj_hdr where tr_id = old.tr_id) then	-- If I'm the last in my group
                delete from %S.tj_tgr where tgrp = old.tr_id;				-- Delete my group record
            end if;
            return old;
        end;
    $$;}
    trigger %S_tj_hdr_tr_ad {} {after delete on %S.tj_hdr for each row execute procedure %S.tj_hdr_tf_ad();}
    
    # Before updating a header record
    #----------------------------------------------------------------
    function %S.tj_hdr_tf_chk() {%S.tj_hdr %S.tj_itm acct.close(varchar)} {
      returns trigger security definer language plpgsql as $$
        declare
            trec	record;
            cdate	date default acct.close('%P');
        begin
            if not old.posted and new.posted then			-- if the entry is being posted
                select sum(amount) as total, count(*) as cnt into trec from %S.tj_itm where id = old.tr_id and seq = old.tr_seq;
                if trec.cnt < 2 then
                    raise exception '!acct.acct.ENC % %', old.tr_id, old.tr_seq;	-- entry not complete
                end if;
                if trec.total != 0 then
                    raise exception '!acct.acct.ENB % %', old.tr_id, old.tr_seq;	-- entry not balanced
                end if;
            end if;
            if session_user != 'dbadmin()' and (old.posted or new.posted) and (old.tr_date <= cdate or new.tr_date <= cdate) then 
                raise exception '!acct.close.DCP % % %', '%S', new.tr_id, new.tr_seq;	-- can't modify anything posted in a closed period
            end if;
            return new;
        end;
    $$;}
    trigger %S_tj_hdr_tr_chk {} {before update on %S.tj_hdr for each row execute procedure %S.tj_hdr_tf_chk();}

    # A record for each debit/credit record
    #----------------------------------------------------------------
    table %S.tj_itm {%S.tj_hdr acct.proj acct.acct acct.cat} {
        id		int
      , seq		int
      , foreign key (id, seq) references %S.tj_hdr on update cascade on delete cascade
      , item		int		default 0
      , primary key (id, seq, item)
      , cmt		varchar
      , proj		varchar		not null references acct.proj on update cascade
      , acct		varchar		not null references acct.acct on update cascade
      , cat		varchar		references acct.cat on update cascade
      , amount		numeric(14,2)	not null
      , recon		date	
    }

    tabtext %S.tj_itm	{Journal Items} 	{Contains an entry for each debit or credit within a given transaction} {
        {id		{Transaction}		{A link to the transaction ID number in the journal header table (i.e. which transaction does this debit or credit belong to)}}
        {seq		{Sequence}		{A link to the transaction sequence number in the journal header table (i.e. which transaction sequence does this debit or credit belong to)}}
        {item		{Item}			{Debits and credits are numbered sequentially by this field within the transaction block}}
        {cmt		{Comment}		{A comment describing the purpose of this specific debit or credit within the transaction block}}
        {proj		{Project}		{A link to the project number for this debit or credit}}
        {acct		{Account}		{A link to the account number for this debit or credit}}
        {cat		{Category}		{A link to the category for this debit or credit}}
        {amount		{Amount}		{The net amount of this debit (+) or credit (-)}}
        {recon		{Reconciled}		{A date indicating the ending date for the statement or control document from which this item was reconciled.  If null, the item has not yet been reconciled.}}
    }

    # Before inserting an item record
    #----------------------------------------------------------------
    function %S.tj_itm_tf_pk() {%S.tj_itm} {
      returns trigger language plpgsql as $$
        begin
            if new.item is null then
                select into new.item coalesce(max(item)+1,0) from %S.tj_itm where id = new.id and seq = new.seq;
            end if;
            return new;
        end;
    $$;}
    trigger %S_tj_itm_tr_pk {} {before insert on %S.tj_itm for each row execute procedure %S.tj_itm_tf_pk();}

    # Combined view
    #----------------------------------------------------------------
    view %S.tj_v {%S.tj_hdr %S.tj_itm acct.acct acct.proj_v} {select
        h.tr_id
      , h.tr_seq
      , i.item
      , eval(fld_list $tran::tj_hdr_v_se h)
      , eval(fld_list $tran::tj_itm_v_se i)
      , case when i.amount >= 0 then  i.amount else null end			as debit
      , case when i.amount <  0 then -i.amount else null end			as credit
      , i.proj ||'.'|| i.acct || coalesce('.'||i.cat,'')			as coding
      , array_agg(i.proj ||'.'|| i.acct || coalesce('.'||i.cat,'')) over (partition by tr_id, tr_seq rows between unbounded preceding and 1 preceding) ||
        array_agg(i.proj ||'.'|| i.acct || coalesce('.'||i.cat,'')) over (partition by tr_id, tr_seq rows between 1 following and unbounded following) as offsets
      , '%S'::varchar								as subl_key
      , '%S' ||' '|| h.tr_id ||' '|| h.tr_seq					as tran_key
      , '%S' ||' '|| h.tr_id ||' '|| h.tr_seq || coalesce(' '||i.item,'')	as item_key
      , sum(amount) over (order by tr_date, tr_id,tr_seq,item)			as balance
      , p.entity
      , p.name									as proj_name
      , a.name									as acct_name
      , eval(fld_list $glob::stampfn h)

        from		%S.tj_hdr	h
        left join	%S.tj_itm	i	on i.id = h.tr_id and i.seq = h.tr_seq
        left join	acct.acct	a	on a.code = i.acct
        left join	acct.proj_v	p	on p.code = i.proj;
    } -grant {
        {glman	s}
    }

    tabtext %S.tj_v	{Journal}	 	{A view which joins the journal header and journal entries into a single unified list} {
        {coding		{Coding}		{A concatenated display of the full account coding for this item which includes: project type, project number, account number, and category code if present}}
        {offsets	{Offset}		{An array of the full account codes for all other debits or credits contained in the same transaction block as this entry}}
        {debit		{Debit}			{Positive (increasing) changes to an account balance are shown in the debit column}}
        {credit		{Credit}		{Negative (decreasing) changes to an account balance are shown in the credit column}}
        {balance	{Balance}		{A running total of debits and credits over the span of the given query}}
        {subl_key	{Sub Ledger Key}	{A code showing the name of the transaction journal this entry is contained in}}
        {tran_key	{Transaction Key}	{A unique identifier showing the journal name, the entry number and the sequence number.  This identifies the transaction block.}}
        {item_key	{Item Key}		{A unique identifier showing the journal name, the entry number, the sequence number and the item number.  This identifies a debit or credit item within a transaction block.}}
        {proj_name	{Proj Name}		{The name of the project this entry is booked to}}
        {acct_name	{Acct Name}		{The name of the account this entry is booked to}}
    }
  
    # When inserting into the view:
    # tr_id	tr_seq	|  item	 |	header		item
    #----------------------------------------------------------------
    # null	null	|  null	 |	insert,seq=0	insert,item=0		OK
    # null	null	|  given |	insert,seq=0	insert,item=0		ignore given item
    # null	given	|  null	 |	insert,seq=0	insert,item=0		ignore given seq
    # null	given	|  given |	insert,seq=0	insert,item=0		ignore given seq,item
    # given	null	|  null	 |	insert,seq=next	insert,item=0		OK
    # given	null	|  given |	insert,seq=next	insert,item=0		ignore given item
    # given	given	|  null	 |	update		insert,item=next	OK
    # given	given	|  given |	update		insert,item=next	ignore given item
    #----------------------------------------------------------------
    function %S.tj_v_tf_ins() {%S.tj_v} {
      returns trigger language plpgsql as $$
        declare
            codes	varchar[];
        begin
--raise notice 'tj_v_tf_ins id:% seq:%', new.tr_id, new.tr_seq;
            if new.tr_id is null or new.tr_seq is null then	-- if no (valid) existing header record specified
                if new.tr_id is null then new.tr_seq := 0; else new.tr_seq := null; end if;
                insert into %S.tj_hdr (eval(fld_list $tran::tj_hdr_tiu)) values (eval(ins_list $tran::tj_hdr_tiu "posted 'f' $glob::stampin")) returning into new.tr_id, new.tr_seq tr_id, tr_seq;
--raise notice '  1         id:% seq:%', new.tr_id, new.tr_seq;
                new.item := 0;
            else					-- assume header already exists
                if (select posted from %S.tj_hdr where tr_id = new.tr_id and tr_seq = new.tr_seq) then
                    raise exception '!acct.acct.CPR % % %', '%S', new.tr_id, new.tr_seq;	-- can't modify posted records
                end if;
                update %S.tj_hdr set eval(upd_list $tran::tj_hdr_iu $glob::stampup) where tr_id = new.tr_id and tr_seq = new.tr_seq returning into new.tr_id, new.tr_seq tr_id, tr_seq;
                new.item := null;
            end if;
--raise notice '  2         id:% seq:%', new.tr_id, new.tr_seq;
            new.amount := coalesce(new.amount,coalesce(new.debit,0)-coalesce(new.credit,0));	-- allow entry into debit/credit fields
            new := %S.codes(new);
            new.recon := null;
--raise notice '  3         id:% seq:%', new.tr_id, new.tr_seq;
            insert into %S.tj_itm (eval(fld_list $tran::tj_itm_tiu)) values (eval(ins_list $tran::tj_itm_tiu {id new.tr_id seq new.tr_seq})) returning into new.item item;
            
--raise notice 'tj_v_tf_ins coding:% offsets:%', new.coding, new.offsets;
            if new.item = 0 and new.offsets is not null then		-- automatically create the other half (item) of the transaction
                new.coding  := new.offsets[1];
                new.offsets := null;	new.proj := null; new.acct := null; new.cat := null;
                new         := %S.codes(new);
                new.amount  := -new.amount;
                new.item    := null;
                insert into %S.tj_itm (eval(fld_list $tran::tj_itm_tiu)) values (eval(ins_list $tran::tj_itm_tiu {id new.tr_id seq new.tr_seq})) returning into new.item item;
            end if;
            return new;
        end;
    $$;}
    trigger %S_tj_v_tr_ins {} {instead of insert on %S.tj_v for each row execute procedure %S.tj_v_tf_ins();}

    # When updating the view:
    # tr_id	tr_seq	|  item	 |	header		item
    #----------------------------------------------------------------
    # null	?	|  ?	 |	nop		nop			No header, ignore
    # ?		null	|  ?	 |	nop		nop			No header, ignore
    # given	given	|  null	 |	update		insert,item=next	create missing item
    # given	given	|  given |	update		update			simple update
    #----------------------------------------------------------------
    function %S.tj_v_tf_upd() {%S.tj_v} {
      returns trigger language plpgsql as $$
        begin
            if old.posted and (new.debit != old.debit or new.credit != old.credit or new.amount != old.amount) then 
                raise exception '!acct.acct.CPR % % %', '%S', old.tr_id, old.tr_seq;	-- can't modify posted records
            end if;

            if new.posted and new.tr_date <= acct.close('%P') then	-- can't post into a closed period
                raise exception '!acct.close.DCP % % %', '%S', old.tr_id, old.tr_seq;
            end if;

            new.amount := coalesce(new.amount,coalesce(new.debit,0)-coalesce(new.credit,0));
            new := %S.codes(new);
            new.recon := null;
            if old.tr_id is null or old.tr_seq is null then		-- if no (valid) existing header record specified
                return null;
            elseif old.item is null then				-- if no item record specified
                new.item := null;
                insert into %S.tj_itm (eval(fld_list $tran::tj_itm_tiu)) values (eval(ins_list $tran::tj_itm_tiu {id old.tr_id seq old.tr_seq})) returning into new.item item;
            else
                update %S.tj_itm set eval(upd_list $tran::tj_itm_iu) where id = old.tr_id and seq = old.tr_seq and item = old.item returning into new.item item;
            end if;
            update %S.tj_hdr set eval(upd_list $tran::tj_hdr_tiu $glob::stampup) where tr_id = new.tr_id and tr_seq = new.tr_seq returning into new.tr_id, new.tr_seq tr_id, tr_seq;
            return new;
        end;
    $$;}
    trigger %S_tj_v_tr_upd {} {instead of update on %S.tj_v for each row execute procedure %S.tj_v_tf_upd();}

    # When deleting from the view
    # tr_id	tr_seq	|  item	 |	header		item
    #----------------------------------------------------------------
    # null	?	|  ?	 |	nop		nop			No header, ignore
    # ?		null	|  ?	 |	nop		nop			No header, ignore
    # given	given	|  null	 |	delete		nop			
    # given	given	|  given |	delete if last	delete, roll-down
    #----------------------------------------------------------------
    function %S.tj_v_tf_del() {%S.tj_v} {
      returns trigger language plpgsql as $$
        begin
            if old.posted then 
                raise exception '!acct.acct.CPR % % %', '%S', old.tr_id, old.tr_seq;	-- can't modify posted records
            end if;

            if old.tr_id is null or old.tr_seq is null then	-- if no (valid) existing header record specified
                return null;
            end if;
            if old.item is not null then			-- There is an item specified for delete
                delete from %S.tj_itm where id = old.tr_id and seq = old.tr_seq and item = old.item;
                update %S.tj_itm set item = item-1 where id = old.tr_id and seq = old.tr_seq and item > old.item;
--raise notice 'tj_v_tf_del found:%', found;
            end if;
            if not exists (select * from %S.tj_itm where id = old.tr_id and seq = old.tr_seq) then	-- if no more items left, delete header too
--raise notice 'tj_v_tf_del hdr';
                delete from %S.tj_hdr where tr_id = old.tr_id and tr_seq = old.tr_seq;
            end if;
            return old;
        end;
    $$;}
    trigger %S_tj_v_tr_del {} {instead of delete on %S.tj_v for each row execute procedure %S.tj_v_tf_del();}

    # Parse a G/L coding string down to its component fields
    # -----------------------------------------------------------------------------
    function {%S.codes(new %S.tj_v)} {%S.tj_v acct.acct acct.cat} {
      returns record language plpgsql as $$
        declare
            codes	varchar[];
        begin
            if new.coding is not null then
                codes := string_to_array(new.coding,'.','');
raise notice 'new.coding:%  codes:%', new.coding, codes;
                if codes[1] != '' and codes[1] is not null then						-- proj specified in coding
                    select into new.proj code from acct.proj where code = codes[1];			-- user entered a code?
                    if not found then
                        select into new.proj code from acct.proj where name ~* codes[1] order by type,numb limit 1;		-- entered a name?
                        if not found then
                            select into new.proj code from acct.proj where numb::varchar = codes[1] order by type,numb limit 1;	-- entered a number
                            if not found then raise exception '!acct.proj.PNF %', codes[1]; end if;
                        end if;
                    end if;
                end if;
                if codes[2] != '' and codes[2] is not null then						-- acct specified in coding
                    select into new.acct code from acct.acct where code = codes[2];			-- user entered a code?
                    if not found then
                        select into new.acct code from acct.acct where numb::varchar = codes[2];	-- entered a number?
                        if not found then
                            select into new.acct code from acct.acct where name ~* codes[2] order by numb limit 1;	-- entered a name?
                            if not found then raise exception '!acct.acct.ANF %', codes[2]; end if;
                        end if;
                    end if;
                end if;
                if codes[3] != '' and codes[3] is not null then						-- cat specified in coding
                    select into new.cat code from acct.cat where code = codes[3];			-- user entered a code?
                    if not found then
                        select into new.cat code from acct.cat where numb::varchar = codes[3];		-- entered a number?
                        if not found then
                            select into new.cat code from acct.cat where name ~* codes[3] order by numb limit 1;	-- entered a name?
                            if not found then raise exception '!acct.cat.CNF %', codes[3]; end if;
                        end if;
                    end if;
                end if;
raise notice '          : % % %', new.proj, new.acct, new.cat;
            end if;
            return new;
        end;
    $$;}

    tabdef %S.tj_v -focus descr -fields {
        {tr_id			ent	9	{1 0}		-hide 1}
        {tr_seq			ent	2	{2 0}		-hide 1}
        {item			ent	3	{3 0}		-hide 1}
        {balance		ent	3	{3 0}		-hide 1 -just r -write 0}
        {descr			ent	30	{1 1}		}
        {posted			ent	1	{2 1}		-state readonly -init f -takefocus 0}
        {offsets		ent	14	{3 1}		-spf {tran::coding %w}}
        {tr_date		ent	11	{4 1}		-spf cal}
        {cmt			ent	40	{1 2 2}		}
        {coding			ent	14	{3 2}		-spf {tran::coding %w}}
        {amount			ent	14	{4 2}		-spf clc -just r -hot 1}
        {proj			ent	6	{2 3}		-hide 1 -write 0 -just r}
        {acct			ent	6	{3 3}		-hide 1 -write 0 -just r}
        {cat			ent	4	{4 3}		-hide 1 -write 0 -just r}
        {debit			ent	11	{5 3}		-hide 1 -write 0 -just r}
        {credit			ent	11	{6 3}		-hide 1 -write 0 -just r}
    }

    # Read-only view of posted entries for inclusion in standard ledgers
    #----------------------------------------------------------------
    view %S.tj_lg_v {%S.tj_hdr %S.tj_itm acct.acct acct.proj} {select
        h.tr_id
      , h.tr_seq
      , i.item
      , h.tr_date
      , h.descr
      , eval(fld_list $tran::tj_itm_v_se i)
      , case when i.amount >= 0 then  i.amount else null end			as debit
      , case when i.amount <  0 then -i.amount else null end			as credit
      , i.proj ||'.'|| i.acct || coalesce('.'||i.cat,'')			as coding
      , '%S'::varchar								as subl_key
      , '%S' ||' '|| h.tr_id ||' '|| h.tr_seq					as tran_key
      , '%S' ||' '|| h.tr_id ||' '|| h.tr_seq || coalesce(' '||i.item,'')	as item_key

        from		%S.tj_hdr	h
        join		%S.tj_itm	i	on i.id = h.tr_id and i.seq = h.tr_seq
    }
  }
}

# Procedure to build a transaction journal for a specified module
#----------------------------------------------------------------
proc tran::journal {module priv min} {
    set tpt $tran::db_objects					;#load up the sql object template
    foreach {s v} [list S $module P $priv M $min] {		;#substitute values for our object set
        regsub -all "%$s" $tpt "$v" tpt
    }
#puts "tpt:$tpt"
    eval $tpt
}

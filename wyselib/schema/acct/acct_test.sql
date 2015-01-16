An alternate view of accounts:


table acct.class {} {
    class_id	int	primary key,
    class_type	acct_types,
    class_name	varchar[32]
    descr	varchar,
    par		int	references acct.class on update cascade
}

table acct.acct {} {
    acct_id	int	primary key,
    acct_type	acct_types,
    acct_name	varchar[32],
    descr	varchar,
}

table acct.proj_types {} {
    type_id	varchar	primary key,
    descr
}

table acct.proj	{} {
    proj_id	int	primary key
    proj_type	varchar references proj_types on update cascade,
    proj_name	varchar,
    descr
    par		int	references acct.proj on update cascade,
}

table acct.map {} {
    proj_type	varchar references acct.proj_types on update cascade,
    acct	int	references acct.acct on update cascade,
    class	int	references acct.class on update cascade
}

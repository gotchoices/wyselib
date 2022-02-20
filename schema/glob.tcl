# Definitions useable across all wyselib modules
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------

module wyselib

namespace eval glob {}
def glob::dba		{dba}
def glob::lang		{en}

def glob::stamps	{
  , crt_date    timestamptz	not null default current_timestamp
  , mod_date    timestamptz	not null default current_timestamp
  , crt_by      name		not null default session_user references base.ent (username) on update cascade
  , mod_by	name		not null default session_user references base.ent (username) on update cascade
}
def glob::stampt	{
    {crt_date   	{Created}               {The date this record was created}}
    {crt_by             {Created By}            {The user who entered this record}}
    {mod_date           {Modified}              {The date this record was last modified}}
    {mod_by             {Modified By}           {The user who last modified this record}}
}
def glob::stampd	{
    {crt_by		ent	10	{1 98}		-opt 1 -wr 0 -sta readonly}
    {crt_date		inf	18	{2 98}		-opt 1 -wr 0 -sta readonly}
    {mod_by		ent	10	{1 99}		-opt 1 -wr 0 -sta readonly}
    {mod_date		inf	18	{2 99}		-opt 1 -wr 0 -sta readonly}
}
def glob::stampin {crt_by session_user mod_by session_user crt_date current_timestamp mod_date current_timestamp}
def glob::stampup {mod_by session_user mod_date current_timestamp}
def glob::stampfn {crt_by mod_by crt_date mod_date}
def glob::stampva {session_user session_user current_timestamp current_timestamp}

def glob::auditt	{
    {a_seq   		{Sequence}	{A sequential number unique to each alteration}}
    {a_date   		{Date/Time}	{Date and time of the change}}
    {a_by   		{Altered By}	{The username of the user who made the change}}
    {a_action  		{Action}	{The operation that produced the change (update, delete)}}
    {a_values   	{Values}	{JSON object containing the old values of the record before the change}}
}

#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------

namespace eval doc {
    def cksum		{/bin/cksum}
    def doc_root	{/usr/local/share/wyatt-docs}		;#store all docs under here
    def logfile		"$doc_root/.vacuum.log"			;#log progress of cleaning/checking
    def doc_del		"$doc_root/.deleted"			;#any docs deleted or updated out of place
    def doc_trash	"$doc_root/.trash"			;#recent files appearing to be leftover from aborted transactions
    def doc_stray	"$doc_root/.stray"			;#other files that don't appear to be valid archive files
    def doc_orphan	"$doc_root/.orphan"			;#large objects that don't have a matching document record
    def doc_tmp		"$doc_root/.verify.tmp"			;#filename for temporary use in verify routine
    def doc_pk		{id}
    def doc_v_in	{id path name version exten cmt locked blob}
    def doc_v_up	$doc_v_in
    def doc_se		[concat $doc_v_up size cksum checked $glob::stampfn]
    def doc_verify	100					;#How many docs to verify at one time
    def doc_archive	100					;#How many docs to re-archive at one time
    def doc_rebuild	100					;#How many large objects to rebuild at one time
}

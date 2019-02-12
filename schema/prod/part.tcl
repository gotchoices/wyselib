# Variables for part table
#Copyright WyattERP.org; See license in root of this package
#----------------------------------------------------------------

namespace eval prod {
    def part_pk		{pnum}
    def part_v_iu	[concat $part_pk base_r parm weight height width length stack recbuy cost lcost cmt]
    def part_se		[concat $part_v_iu parm_c $glob::stampfn]
#    def part_j_se	[lremove $part_se base_r]
    def part_v_se	[concat $part_se volume]
    
    def	part_pnum_min	1000
}

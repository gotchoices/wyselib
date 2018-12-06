# Support functions for product documentation
#------------------------------------------
#Copyright WyattERP, all other rights reserved
package provide wyselib 0.20

#TODO:
#X- Display a preview of all product documents
#X- When loading a base in prodim, refresh with docs relational to that base
#- Dbe available for changing cmt, locked
#- Allow to clone a new doc from an existing doc
#- Allow to add a new doc from the filesystem
#-  Detect file format?
#-  Use correct file extension?
#-  Create a path for the document
#-  If conflicts with existing doc:
#-    If existing locked, create later version
#-    If existing not locked ask to overwrite, or create later version
#- Allow to view existing doc
#- Allow to launch editor for existing doc (platform dependent)
#- Allow to fetch/checkout a doc with all its dependencies into a work directory
#- Allow to fetch/checkout a doc into an existing document group (create new dependency)
#- Allow to write/commit the doc and its changed dependencies back into the database
#-  Detect other docs in the work directory
#-  Check for other docs modified--make sure they were checked out too
#-  Check for rendered docs in the directory--make sure they were updated too
#- Allow to create docs with open or locked status
#- Allow to later lock docs not yet locked
#- Allow to have multiple docs fetched/checked_out at a time
#- Be able to restore context after re-launching prodim
#- Browse fetched/checked_out docs
#- Be able to delete working directories if the file is not checked out (and/or after checking back in)
#- Launch editors on any document in the group
#- Allow to delete unlocked documents if there are no conflicting dependencies
#- 
#- 
#- 

namespace eval pdoc {
    namespace export pdoc_menu open_build logmenu new
    variable v
    set v(nfname)	{}
}

# Create a menu item for logging documents to a basename
#------------------------------------------
proc pdoc::logmenu {mw args} {
    variable cfig
    
    $mw menu mb log -under 0 -help {Import documents to the database and associate them with the currently selected basename}
    foreach rec [sql::qlist "select type, descr from prod.doc_type order by type"] {
        lassign $rec type descr
        $mw menu log mi $type "$type - $descr" -under 0 -help "Import one or more files of type: $descr" -command "pdoc::new $type"
    }
}

# Import a new document from the filesystem
#------------------------------------------
proc pdoc::new {type {base {}}} {
    variable v
    if {$base == {}} {catch {set base [prod verse get base]}}		;#attempt to get base from an open product window
    if {$base == {}} {
        if {[eval scm::dia \{Select a basename\} -dest base [dew::scm base]] < 0} return
    }
    set ask_cmt [sql::value prod.doc_type count(*) -where "autolock and type = '$type'"]
    if {[sfile::dia {Select one or more files to import} -dest v(impfiles) -op {Import} -mask {*} -wait 1 -selectmode extended] < 0} {return 0}
#puts "pdoc::new type:$type base:$base files:$v(impfiles)"
    foreach file $v(impfiles) {
        set path "prodim $base"
        set name [file rootname [file tail $file]]
        set exten [string range [file extension $file] 1 end]
        if {$ask_cmt} {
            if {[dia::query "Documents of type: $type will be locked on first write.\nSo please enter a comment for the file now:" cmt 0 OK Cancel] < 0} {return}
        } else {
            set cmt {}
        }
        set query "insert into prod.doc_v (base_r,type_r,name,exten,cmt,blob) values ('$base','$type','$name','$exten','[sql::escape $cmt]',%O) returning id;"
#puts "query:$query"
        sql::lo_import $file $query
    }
    catch {pdoc p reload}
}

# Delete a document
#------------------------------------------
proc pdoc::delete {w} {
    if {![base::priv_check super]} return
    set docs [llength [set keys [$w.p keys]]]
    if {[dia::ask "Delete [plural $docs document]: ($keys)\nAre you sure:" 0 {Yes, delete} {Cancel delete}] < 0} return
    set query "delete from prod.doc_v where id in ([join $keys ,]);"
#puts "query:$query"
    sql::x $query
    $w p reload
}

# When the user double-clicks a document
#------------------------------------------
proc pdoc::execute {w args} {
puts "execute w:$w args:$args"
return

Call pdoc::open
    if {$x == 1} {
        lappend ids $id
        view $ids 
    } else {
        view $id 
    }
}

# Make a toplevel window for product documents
#----------------------------------------------------
proc pdoc::open_build {w args} {
    variable cfig

    set m [$w menu w]
    $m mb tools -under 0 -help {Common functions related to this module}
    $m mb rept Reports -under 0 -help {Reports pertaining to this module}

    top::add [dbp::dbp $w.p {*}$cfig(pdocp)] pdocp
    pack $w.p -side top -fill both -exp yes
    return 1
}

# General preview window for viewing product documents
#----------------------------------------------------
top::menu pdoc pdoc Docs {Product Documents} {Open a new window for viewing/editing documents associated with products} -write 1
proc pdoc::pdoc_build {w args} {
    variable cfig

    argnorm {{load 1} {write 2}} args
    array set cfig "load$w 0 write$w 0"
    foreach s {load write} {xswitchs $s args cfig($s$w)}

    top::add [dbp::dbp $w.p -table prod.doc_v -see end {*}$wyselib::dbpbuts -selectmode extended\
        -disp {id base_r name version exten cmt ckkout locked size mod_date mod_by} -order {relname}\
        -execute {pdoc::execute %w}] p

    pack $w.p -side top -fill both -expand yes
    $w.p listbox configure -width 800 -height 200		;#default sizing

    $w menu mb tools -under 0 -help {Functions for operating on product documents}
    $w menu tools mi vdoc  {View Document} -under 0 -s {View -bg lightgreen -gmc {-exp 1}} -command "pdoc::wview $w"	-help {View the document highlighted in the preview pane}
    $w menu tools mi edoc  {Open Document} -under 0 -s {Open}		-command "pdoc::open $w"			-help {Open the document highlighted in the preview pane, using an editor appropriate for its type (Does not modify document in database).}

    if {$cfig(write$w)} {
        $w menu tools mi sep
        $w menu tools mi ckout {Checkout Document} -under 5 -s {Checkout -bg pink} -command "pdoc::checkout $w"	-help {Open the current document in exclusive writeable mode (will allow changes to document in database)}
        $w menu tools mi ckin  {Checkin Document}		-command "pdoc::checkin $w"	-help {Clear the "checked out" status of a document}
        $w menu tools mi new   {New Document}		-s New	-command "pdoc::new"		-help {Add a new product document into the database}
        $w menu tools mi del   {Delete Document}		-command "pdoc::delete $w"	-help {Delete a document from the database}
    }
#    if {[priv::haspriv usr -priv camque]} {
#	$w menu tools mi exp   {Export Document}		-command "pdoc::export $w"	-help {Export document to specified file}
#    }

    $w menu help mi help {Product Document Help} -help {Get help with using this window (product documents)} -command "help::locate pdoc.html" -before app

    if {$cfig(load$w)} {after idle "$w.p load"}
    return 1
}

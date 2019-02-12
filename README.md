## Wyselib: WyattERP Schema Library

Wyselib is a library of reusable SQL objects and object creating functions that 
can make it quicker and easier to create a database application.

The objects supplied in the library are authored in the format recognized by 
the [Wyseman](http://github.com/gotchoices/wyseman) schema manager.

You can make your own objects and add them on top of the basic design provided 
by Wyselib.  And you only need to use the parts of the library you want.

Wyselib also includes a number of run-time control-layer functions for handling
pre-defined actions, associated with the database tables and views that are 
built by this schema.  These are typically used for generating reports or 
calling stored procedures in the database.  Action handlers for javascript can 
be accessed by requiring them from this package:

let { actions } = require('wyselib')

There is also a small parser you can access as:

let { Parser } = require('wyselib')

that is good for digesting your own action handlers you may define for your
own tables and views.  It is called with an object you will use to store
your action lookup table, and an array of objects required from your own
handler files.  See the index.js file in this package for an example of how
this is done.

Wyselib also includes a number of legacy run-time modules targetd for Tcl/Tk.
These are not needed for new application development in a browser using 
[Wylib](http://github.com/gotchoices/wylib).

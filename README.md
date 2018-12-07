## Wyselib: WyattERP Schema Library

Wyselib is a library of reusable SQL objects and object creating functions 
that can make it quicker and easier to create a database application.

The objects supplies in the library are authored in the format recognized
by the [Wyseman](http://github.com/gotchoices/wyseman) schema manager.

You can make your own objects and add them on top of the basic design
provided by Wyselib.  And you only need to use the parts of the library
you want.

Wyselib also includes a number of run-time TCL modules historically a part of
ERP client applications which themselves (written in Tcl/Tk).  These are not
needed for new application development in the browser using 
[Wylib](http://github.com/gotchoices/wylib).  However, this library will likely contain
analagous javascript modules in the future.

### Status
Wyselib is being ported from a legacy codebase and so is currently a work in progress.
The goal is primarily to support the 
[MyCHIPs project](http://www.gotchoices.org/mychips/index.html).
But can also be used to build any database schema.


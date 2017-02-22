LIBNAME=wyselib
VERSION=0.20
OBJS=acct.tcl base.tcl pdoc.tcl prod.tcl proj.tcl tran.tcl init.tcl

#Allow the user to install where he wants
ifeq ("$(WYLIB)","")
    LIBDIR=/usr/lib
else
    LIBDIR=${WYLIB}
endif

PKGNAME=${LIBNAME}-${VERSION}
INSTDIR=${LIBDIR}/${PKGNAME}
HTMLDIR=${INSTDIR}/html

all: pkgIndex.tcl

pkgIndex.tcl: ${OBJS}
	wmmkpkg ${LIBNAME} ${VERSION}
#	echo "pkg_mkIndex -lazy . ${OBJS}" | tclsh

install: all
	if ! [ -d ${INSTDIR} ] ; then mkdir ${INSTDIR} ; fi
	install -m 644 ${OBJS} pkgIndex.tcl ${INSTDIR}
#	install -m 755 libwaplib.so ${INSTDIR}

uninstall:
	rm -rf ${INSTDIR}

clean:
	rm -f pkgIndex.tcl

release: 
	mkrelease ${LIBNAME} ${VERSION}

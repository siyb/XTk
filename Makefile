prefix = ${DESTDIR}

install:
	echo "pkg_mkIndex -verbose -direct ." | tclsh
	install -Dm755 "XTk.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/XTk.tcl"
	install -Dm644 "pkgIndex.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/pkgIndex.tcl"
	install -Dm755 "xtkutil.tcl" "${DESTDIR}/usr/bin/xtkutil"

uninstall:
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/XTk.tcl
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/pkgIndex.tcl
	rm -f ${DESTDIR}/usr/bin/xtkutil

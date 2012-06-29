prefix = ${DESTDIR}

install:
	echo "pkg_mkIndex -verbose -direct ." | tclsh8.6
	install -Dm644 "XTk.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/XTk.tcl"
	install -Dm644 "codegenerator.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/codegenerator.tcl"
	install -Dm644 "parser.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/parser.tcl"
	install -Dm644 "pkgIndex.tcl" "${DESTDIR}/usr/lib/tcltk/XTk/pkgIndex.tcl"
	install -Dm755 "xtkutil.tcl" "${DESTDIR}/usr/bin/xtkutil"

uninstall:
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/XTk.tcl
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/codegenerator.tcl
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/parser.tcl
	rm -f ${DESTDIR}/usr/lib/tcltk/XTk/pkgIndex.tcl
	rm -f ${DESTDIR}/usr/bin/xtkutil
clean:
	rm -f pkgIndex.tcl

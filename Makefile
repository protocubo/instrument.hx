libname=uinstrument
zipname=${libname}.zip

test:
	haxe test.hxml
	for i in basic call_stacks; do (echo example: $$i && cd examples && haxe $$i.hxml && neko $$i.n); done

${zipname}:
	rm -f ${zipname}
	zip -r $@ ./* -x \*.zip

set-pkg: ${zipname}
	haxelib dev ${libname}
	haxelib remove ${libname}
	haxelib install ${zipname}
	haxelib path ${libname}

set-dev:
	haxelib dev ${libname} ${PWD}
	haxelib path ${libname}

set-live:
	haxelib dev ${libname}
	haxelib remove ${libname}
	haxelib install ${libname}
	haxelib path ${libname}

.PHONY: test ${zipname} set-pkg set-dev set-live

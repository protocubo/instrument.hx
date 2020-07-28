import uinstrument.Tools.defaultTrace in itrace;

class CallStacks {
	static function onCalled(?pos:haxe.PosInfos)
	{
		itrace('CALL ${pos.className}.${pos.methodName}', pos);

		// remove onCalled and the instrumented function, and limit the
		// number of call stack items to display to two
		var cs = haxe.CallStack.callStack();
		var pcs = cs.slice(2, 4);
		for (i in haxe.CallStack.toString(pcs).split("\n")) {
			if (StringTools.trim(i) != "")
				itrace(' └╴ $i', pos);
		}
		var ommited = cs.length - pcs.length - 2;
		if (ommited > 0)
			itrace('    [$ommited ommited]', pos);
	}

	static function main()
	{
		uinstrument.TraceCalls.onCalled = onCalled;
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}

import uinstrument.Tools.defaultTrace in itrace;

class CallStacks {
	static function onCalled(?pos:haxe.PosInfos)
	{
		itrace('CALL ${pos.className}.${pos.methodName}', pos);
		if (pos.className == "Std") {
			/*
			trace the call stack as well

			for this, use haxe.CallStack.callStack, but:
			 - remove the calls to this and the instrumented functions
			 - limit the number of call stack items traced
			*/
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
	}

	static function main()
	{
		uinstrument.TraceCalls.onCalled = onCalled;
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}

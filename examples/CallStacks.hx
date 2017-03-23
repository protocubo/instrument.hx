import instrument.DefaultOutput.trace in itrace;

class CallStacks {
	static function onCalled(?pos:haxe.PosInfos)
	{
		itrace('CALL ${pos.className}.${pos.methodName}', pos);
		if (pos.className == "Std") {
			var cs = haxe.CallStack.callStack();
			var pcs = cs.slice(2,4);  // remove onCalled and targeted calls
			for (i in StringTools.trim(haxe.CallStack.toString(pcs)).split("\n"))
				itrace(' └╴ $i', pos);
			if (cs.length - 1 > pcs.length)
				itrace('    [${cs.length - pcs.length -1} ommited]', pos);
		}
	}

	public static function main()
	{
		instrument.TraceCalls.onCalled = onCalled;
		Basic.main();
	}
}


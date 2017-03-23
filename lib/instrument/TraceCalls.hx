package instrument;

import haxe.macro.Expr;

class TraceCalls {
	public static dynamic function onCalled(?pos:haxe.PosInfos)
	{
#if instrument_no_default
#else
		var msg = 'CALL ${pos.className}.${pos.methodName}';
#if instrument_stderr_default
		Sys.stderr().writeString(msg + "\n");
#else
		haxe.Log.trace(msg, pos);
#end
#end
	}

#if macro
	public static function hijack(type:String, ?field:String)
		Instrument.hijack(instrument.TraceCalls.embed, type, field);

	@:allow(instrument.Instrument)
	static function embed(field:Field, fun:Function):Function
	{
		if (fun.expr == null)
			return fun;
		fun.expr = macro {
			@:pos(fun.expr.pos) instrument.TraceCalls.onCalled();
			${fun.expr};
		}
		return fun;
	}
#end
}


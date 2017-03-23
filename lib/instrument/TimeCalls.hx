package instrument;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

typedef Seconds = Float;

class TimeCalls {
	static var auto:Array<{ divisor:Float, symbol:String }>;
	
	/*
	Make `auto` available as soon as possible

	Make sures it's already available if we're timing other `__init__`
	functions.
	*/
	static function __init__()
	{
		auto = [
			// divisor := 1/factor
			// keep sorted
			{ divisor:1/3600, symbol:"hour" },
			{ divisor:1/60, symbol:"min" },
			{ divisor:1, symbol:"s" },
			{ divisor:1e3, symbol:"ms" },
			{ divisor:1e6, symbol:"μs" },
			{ divisor:1e9, symbol:"ns" }
		];
	}

	public static var unit:Null<{ divisor:Float, symbol:String }> = null;  // default to auto mode

	public static function autoScale(t:Seconds):{ divisor:Float, symbol:String }
	{
		// first, find the ideal divisor
		var d = t != 0 ? 1/t : Math.POSITIVE_INFINITY;
		// then, find the best match
		var u = Lambda.find(auto, function (i) return i.divisor >= d);
		if (u == null)
			u = auto[auto.length - 1];
		return u;
	}

	public static dynamic function onTimed(start:Seconds, finish:Seconds, ?pos:haxe.PosInfos)
	{
		var t = finish  - start;
		var u = unit != null ? unit : autoScale(t);
		haxe.Log.trace('TIME ${Math.round(t*u.divisor)}${u.symbol} on ${pos.className}.${pos.methodName}', pos);
	}

#if macro
	// FIXME remove the need for skipFinal?  or, at least, rename it?
	public static function hijack(type:String, ?field:String, ?skipFinal=false)
		Instrument.hijack(instrument.TimeCalls.embed.bind(skipFinal), type, field);

	static function embedExit(e:Expr):Expr
	{
		return
			switch e.expr {
			case EReturn(null):
				macro {
					@:pos(e.pos) instrument.TimeCalls.onTimed(__ins_start__, Sys.time());
					return;
				}
			case EReturn(u) if (u != null):
				macro {
					var __ins_ret__ = $u;
					@:pos(e.pos) instrument.TimeCalls.onTimed(__ins_start__, Sys.time());
					return __ins_ret__;
				}
			case EThrow(u):
				macro {
					var __ins_ret__ = $u;
					@:pos(e.pos) instrument.TimeCalls.onTimed(__ins_start__, Sys.time());
					throw __ins_ret__;
				}
			case EFunction(_):
				e;
			case _:
				e.map(embedExit);
			}
	}

	@:allow(instrument.Instrument)
	static function embed(skipFinal:Bool, field:Field, fun:Function):Function
	{
		if (fun.expr == null)
			return fun;
		var body = [
			(macro var __ins_start__ = Sys.time()),
			embedExit(fun.expr)
		];
		if (!skipFinal) {
			body.push(
				macro @:pos(fun.expr.pos) instrument.TimeCalls.onTimed(__ins_start__, Sys.time())
			);
		}
		fun.expr = macro $b{body};
		return fun;
	}
#end
}


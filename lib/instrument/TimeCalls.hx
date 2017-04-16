package instrument;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

typedef Seconds = Float;

class TimeCalls {
	static var auto:Array<{ divisor:Float, symbol:String }>;
	
	/*
	Make sure `auto` is available.

	Only initializes `auto` once.
	*/
	static inline function initAuto()
	{
		if (auto == null) {
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
	}

	public static var unit:Null<{ divisor:Float, symbol:String }> = null;  // default to auto mode

	public static function autoScale(t:Seconds):{ divisor:Float, symbol:String }
	{
		initAuto();
		// find the ideal divisor
		var d = t != 0 ? 1/t : Math.POSITIVE_INFINITY;
		// find the best among the available divisors (default to largest)
		var best = auto.length - 1;
		for (i in 0...best) {
			if (auto[i].divisor >= d) {
				best = i;
				break;
			}
		}
		// check if a smaller divisor isn't just as good, after Math.round
		if (best > 0) {
			var exp = Math.round(t*auto[best].divisor);
			var alt = t*auto[best - 1].divisor;
			var expToAlt = exp/auto[best].divisor*auto[best - 1].divisor;
			if (exp > 0 && expToAlt > alt)
				best--;
		}
		return auto[best];
	}

	public static dynamic function onTimed(start:Seconds, finish:Seconds, ?pos:haxe.PosInfos)
	{
#if !instrument_no_default
		var t = finish  - start;
		var u = unit != null ? unit : autoScale(t);
		Tools.defaultTrace('TIME ${Math.round(t*u.divisor)}${u.symbol} on ${pos.className}.${pos.methodName}', pos);
#end
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


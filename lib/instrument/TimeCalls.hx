package instrument;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

class TimeCalls {
	public static dynamic function onTimed(start:Float, finish:Float, ?pos:haxe.PosInfos)
		haxe.Log.trace('TIME ${Math.round((finish-start)*1e6)}us on ${pos.className}.${pos.methodName}', pos);

#if macro
	public static function hijack(type:String, ?field:String)
		Instrument.hijack(instrument.TimeCalls.embed, type, field);

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
			case _:
				e.map(embedExit);
			}
	}

	@:allow(instrument.Instrument)
	static function embed(field:Field, fun:Function):Function
	{
		var body = embedExit(fun.expr);
		fun.expr = macro @:pos(field.pos) {
			var __ins_start__ = Sys.time();
			$body;
			instrument.TimeCalls.onTimed(__ins_start__, Sys.time());
		}
		return fun;
	}
#end
}


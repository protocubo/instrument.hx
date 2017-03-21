package instrument;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

// FIXME rename
class Timer {
	// FIXME split into call and exit events
	public static dynamic function notify(start:Float, finish:Float, ?pos:haxe.PosInfos)
		trace('TIME ${Math.round((finish-start)*1e6)}us on ${pos.className}.${pos.methodName}');

	public static function hijack(type:String, ?field:String)
		Instrument.hijack(instrument.Timer.embed, type, field);

	static function embedExit(e:Expr):Expr
	{
		return
			switch e.expr {
			case EReturn(_), EThrow(_):
				macro @:pos(e.pos) {
					// FIXME compute the return/throw value first
					instrument.Timer.notify(__ins_start__, Sys.time());
					$e;
				}
			case _:
				e.map(embedExit);
			}
	}

	@:allow(instrument.Instrument)
	static function embed(e:Expr):Expr
	{
		var body = embedExit(e);
		return macro @:pos(e.pos) {
			var __ins_start__ = Sys.time();
			$body;
			instrument.Timer.notify(__ins_start__, Sys.time());
		}
	}
}


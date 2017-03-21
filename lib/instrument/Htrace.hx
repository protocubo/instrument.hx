package instrument;

import haxe.macro.Expr;

// FIXME rename
class Htrace {
	public static dynamic function notify(?pos:haxe.PosInfos)
		trace('CALL ${pos.className}.${pos.methodName}');

	public static function hijack(type:String, ?field:String)
		Instrument.hijack(instrument.Htrace.embed, type, field);

	@:allow(instrument.Instrument)
	static function embed(e:Expr):Expr
	{
		return macro @:pos(e.pos) {
			instrument.Htrace.notify();
			$e;
		}
	}
}


package instrument;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
using StringTools;

using haxe.macro.ExprTools;

private typedef Opts = {
	?field:String,
	?start:String,
	?finish:String
}

class Instrument {
	static function serialize(v:Opts):String
	{
		var s = new haxe.Serializer();
		s.serialize(v);
		return s.toString();
	}

	static function unserialize(v:String):Opts
	{
		var u = new haxe.Unserializer(v);
		return u.unserialize();
	}

	public static function instrument(opts)
	{
		var opts = unserialize(opts);
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		for (f in fields) {
			if (opts.field != null && f.name != opts.field)
				continue;
			switch f.kind {
			case FFun(fun):
				// FIXME just map, don't parse again
				var start = opts.start != null ? Context.parse(opts.start, f.pos) : macro {};
				var finish = opts.finish != null ? Context.parse(opts.finish, f.pos) : macro {};
				fun.expr =
					macro {
						$start;
						// FIXME handle Void
						// FIXME handle untyped (haxe issue)
						var __actual__ = (function () ${fun.expr})();
						$finish;
						return __actual__;
					}
			case FVar(_), FProp(_):
				Context.warning("Unsupported (yet): FVAR, FProp", pos);
			}
		}
		return fields;
	}

	public static function hijack(type, ?field, ?start, ?finish)
	{
		var opts = serialize({ field:field, start:start, finish:finish });
		Compiler.addMetadata('@:build(instrument.Instrument.instrument("$opts"))', type);
	}
}


package instrument;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
using StringTools;

using haxe.macro.ExprTools;

class Instrument {
#if macro
	static var methods = new Array<Function->Function>();

	public static function instrument(id:Int, ?only:String)
	{
		var embed = methods[id];
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		for (f in fields) {
			if (only != null && f.name != only)
				continue;
			switch f.kind {
			case FFun(fun):
				f.kind = FFun(embed(fun));
			case FVar(_), FProp(_):
			}
		}
		return fields;
	}

	public static function hijack(embed:Function->Function, type:String, ?field:String)
	{
		var id = methods.push(embed) - 1;
		var bcall = macro instrument.Instrument.instrument($v{id}, $v{field});
		// FIXME register dependencies with the compilation cache
		// FIXME gracefully fail on macro, @:build, and @:genericBuild
		Compiler.addMetadata('@:build(${bcall.toString()})', type);
	}
#end
}


package instrument;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
using StringTools;

using haxe.macro.ExprTools;

class Instrument {
	static var methods = new Array<Expr->Expr>();

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
				fun.expr = embed(fun.expr);
			case FVar(_), FProp(_):
			}
		}
		return fields;
	}

	public static function hijack(embed:Expr->Expr, type:String, ?field:String)
	{
		var id = methods.push(embed) - 1;
		var bcall = macro instrument.Instrument.instrument($v{id}, $v{field});
		// FIXME register dependencies with the compilation cache
		// FIXME gracefully fail on macro, @:build, and @:genericBuild
		Compiler.addMetadata('@:build(${bcall.toString()})', type);
	}
}


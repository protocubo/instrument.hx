package instrument;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
using StringTools;

using haxe.macro.ExprTools;

class Instrument {
#if macro
	static var methods = new Array<Field->Function->Function>();

	public static function instrument(id:Int, type:String, ?only:String)
	{
		var embed = methods[id];
		var fields = Context.getBuildFields();
		for (f in fields) {
			if (only != null && f.name != only)
				continue;
			// FIXME skip AMacro
			switch f.kind {
			case FFun(fun) if (f.access.indexOf(AInline) < 0):
				f.kind = FFun(embed(f, fun));
			case FFun(fun) if (only != null):
				Context.warning('Removing AInline access from $type.$only', (macro {}).pos);
				f.access.remove(AInline);
				f.kind = FFun(embed(f, fun));
			case FVar(_), FProp(_) if (only != null):
				Context.warning('Igoring $type.$only: FVar or FProp', (macro {}).pos);
			case _:
			}
		}
		return fields;
	}

	public static function hijack(embed:Field->Function->Function, type:String, ?field:String)
	{
		var id = methods.push(embed) - 1;
		var bcall = macro instrument.Instrument.instrument($v{id}, $v{type}, $v{field});
		// FIXME register dependencies with the compilation cache
		// FIXME gracefully fail on macro, @:build, and @:genericBuild
		Compiler.addGlobalMetadata(type, '@:build(${bcall.toString()})', false, true);
	}
#end
}


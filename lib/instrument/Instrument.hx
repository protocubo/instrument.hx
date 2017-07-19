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
		// EXPLORE give more control to the implementation (e.g. change field properties)
		var embed = methods[id];
		var fields = Context.getBuildFields();
		var noInline = Context.defined("no_inline");
		for (f in fields) {
			if (only != null && f.name != only)
				continue;
			// FIXME ignore AMacro
			switch f.kind {
			case FFun(fun) if (f.access.indexOf(AInline) < 0 || noInline):
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

	// EXPLORE use path filters instead of explicit types
	// EXPLORE allow field filters
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


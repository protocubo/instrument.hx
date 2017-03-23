package instrument;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

class TraceArgs {
	public static dynamic function onCalled(args:Array<{ name:String, value:Dynamic }>, ?pos:haxe.PosInfos)
	{
#if instrument_no_default
#else
		var targs = args.map(function (i) return '${i.name}=<${i.value}>');
		var msg = 'CALL ${pos.className}.${pos.methodName}(${targs.join(", ")})';
#if instrument_stderr_default
		Sys.stderr().writeString(msg + "\n");
#else
		haxe.Log.trace(msg, pos);
#end
#end
	}

#if macro
	public static function hijack(type:String, ?field:String)
		Instrument.hijack(instrument.TraceArgs.embed, type, field);

	static function changeIdents(dict:Map<String,String>, e:Expr):Expr
	{
		return
			switch e.expr {
			case EConst(CIdent(name)) if (dict.exists(name)):
				macro $i{dict[name]};
			case _:
				e.map(changeIdents.bind(dict));
			}
	}

	@:allow(instrument.Instrument)
	static function embed(field:Field, fun:Function):Function
	{
		if (fun.expr == null)
			return fun;
		var dict = new Map();
		var i = 0;
		var block = fun.args.map(
			function (arg)
			{
				var tname = '__ins_arg_${i}__';
				dict[arg.name] = tname;
				return macro var $tname = $i{arg.name};
			}
		);
		var sargs = fun.args.map(
			function (arg)
			{
				var tname = dict[arg.name];
				return macro { name:$v{arg.name}, value:($i{tname}:Dynamic) };
			}
		);
		block.push(macro
			{
				var args = $a{sargs};
				@:pos(fun.expr.pos) instrument.TraceArgs.onCalled(args);
			}
		);
		block.push(changeIdents(dict, fun.expr));
		fun.expr = macro $b{block};
		return fun;
	}
#end
}



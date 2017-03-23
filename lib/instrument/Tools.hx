package instrument;

class Tools {
	@:noUsing
	public static inline function defaultTrace(msg:String, pos:haxe.PosInfos)
	{
#if instrument_no_default
#elseif instrument_stderr_default
		Sys.stderr().writeString(msg + "\n");
#elseif instrument_trace_default
		haxe.Log.trace(msg, pos);
#elseif js
		console.log(msg);
#elseif sys
		Sys.stderr().writeString(msg + "\n");
#else
		haxe.Log.trace(msg, pos);
#end
	}
}


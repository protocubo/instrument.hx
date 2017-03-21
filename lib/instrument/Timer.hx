package instrument;

class Timer {
	public static dynamic function notify(start:Float, finish:Float, ?pos:haxe.PosInfos)
		trace('TIME ${Math.round((finish-start)*1e6)}us on ${pos.className}.${pos.methodName}');

	public static function hijack(type:String, ?field:String)
		Instrument.hijack(type, field, "var __start__ = Sys.time()", "instrument.Timer.notify(__start__, Sys.time())");
}


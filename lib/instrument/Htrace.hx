package instrument;

class Htrace {
	public static dynamic function notify(?pos:haxe.PosInfos)
		trace('CALL ${pos.className}.${pos.methodName}');

	public static function hijack(type:String, ?field:String)
		Instrument.hijack(type, field, "instrument.Htrace.notify()");
}


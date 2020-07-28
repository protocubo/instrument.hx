# µinstrument.hx – Micro framework for Haxe instrumentation

## A visual example

```haxe
// Basic.hx
class Basic {
	public static function main()
	{
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}
```

```hxml
# basic.hxml
-neko basic.n
-main Basic
-lib uinstrument
--macro uinstrument.TimeCalls.hijack("haxe.Json", "parse")
--macro uinstrument.TraceCalls.hijack("haxe.format.JsonParser")
--macro uinstrument.TraceArgs.hijack("Std", "parseFloat")
--macro uinstrument.TraceArgs.hijack("Std", "int")
```

```
$ haxe basic.hxml
uinstrument/Instrument.hx:29: characters 72-74 : Warning : Removing AInline access from haxe.Json.parse
```

```
$ neko basic.n
CALL haxe.format.JsonParser.new
CALL haxe.format.JsonParser.parseRec
CALL haxe.format.JsonParser.parseString
CALL haxe.format.JsonParser.parseRec
CALL Std.parseFloat(x=<33.3>)
CALL Std.int(x=<33.3>)
TIME 186μs on haxe.Json.parse
Basic.hx:4: { value => 33.3 }
```

## Tracing calls and arguments

For simple call tracing, it's enough to use
`uinstrument.TraceCalls.hijack(<class name>, ?<method name>)`.  This will adapt
the desired methods to call `uinstrument.TraceCalls.notify` at their beginning.

```hxml
# basic.hxml
-neko basic.n
-main Basic
-lib uinstrument
--macro uinstrument.TraceCalls.hijack("haxe.format.JsonParser")
```

```
$ haxe basic.hxml
uinstrument/Instrument.hx:29: characters 72-74 : Warning : Removing AInline access from haxe.Json.parse

$ neko basic.n
CALL haxe.format.JsonParser.new
CALL haxe.format.JsonParser.parseRec
CALL haxe.format.JsonParser.parseString
CALL haxe.format.JsonParser.parseRec
Basic.hx:4: { value => 33.3 }
```

If, on the other hand, inspection of the arguments is desired, `TraceCalls`
should be replaced by `TraceArgs`: this will instead call its `notify` function
with an extra `args:Array<{ name:String, value:Dynamic }>` array.  The
arguments for `TraceArgs` are the same as those for `TraceCalls`.

```hxml
# basic.hxml
-neko basic.n
-main Basic
-lib uinstrument
--macro uinstrument.TraceArgs.hijack("Std", "parseFloat")
--macro uinstrument.TraceArgs.hijack("Std", "int")
```

```
$ haxe basic.hxml
uinstrument/Instrument.hx:29: characters 72-74 : Warning : Removing AInline access from haxe.Json.parse

$ neko basic.n
CALL Std.parseFloat(x=<33.3>)
CALL Std.int(x=<33.3>)
Basic.hx:4: { value => 33.3 }
```

Tracing arguments can be used, for example, to debug database accesses
performed by record-macros managers, or to analyze the behavior of other
complex macro-generated pieces of code.

```hxml
-lib uinstrument
--macro uinstrument.TraceArgs.hijack("sys.db.Sqlite.SqliteConnection", "request")
--macro uinstrument.TraceArgs.hijack("sys.db.Mysql.MysqlConnection", "request")
```

_(Of course you should not leave this on in production; at the very least make
sure to sanitize the output so no sensitive information ever gets stored in log
files)._

Note that `TraceCalls.notify` and `TraceArgs.notify` are `dynamic` functions
and can be replaced at runtime: see [_Customizing the callbacks: tracing call
stacks_] (#customizing-the-callbacks-tracing-call-stacks) for an example.

## Timing calls

Similar to call and argument tracing, `uinstrument.TimeCalls.hijack(<class
name>, ?<method name>)` can be used to track the amount of time spent in some
functions of interest.

By default the time spent is traced for every call, but [_customizing the
callbacks_] (#customizing-the-callbacks-tracing-call-stacks) allows these
results to be manipulated freely, for example for aggregation or plotting.

```hxml
# basic.hxml
-neko basic.n
-main Basic
-lib uinstrument
--macro uinstrument.TimeCalls.hijack("haxe.Json", "parse")
```

```
$ haxe basic.hxml
uinstrument/Instrument.hx:29: characters 72-74 : Warning : Removing AInline access from haxe.Json.parse

$ neko basic.n
TIME 186μs on haxe.Json.parse
Basic.hx:4: { value => 33.3 }
```

## Customizing the callbacks: tracing call stacks

```haxe
// CallStacks.hx
import uinstrument.Tools.defaultTrace in itrace;

class CallStacks {
	static function onCalled(?pos:haxe.PosInfos)
	{
		itrace('CALL ${pos.className}.${pos.methodName}', pos);
		if (pos.className == "Std") {
			/*
			trace the call stack as well

			for this, use haxe.CallStack.callStack, but:
			 - remove the calls to this and the instrumented functions
			 - limit the number of call stack items traced
			*/
			var cs = haxe.CallStack.callStack();
			var pcs = cs.slice(2, 4);
			for (i in haxe.CallStack.toString(pcs).split("\n")) {
				if (StringTools.trim(i) != "")
					itrace(' └╴ $i', pos);
			}
			var ommited = cs.length - pcs.length - 2;
			if (ommited > 0)
				itrace('    [$ommited ommited]', pos);
		}
	}

	static function main()
	{
		uinstrument.TraceCalls.onCalled = onCalled;
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}
```

```hxml
# call_stacks.hxml
-neko call_stacks.n
-main CallStacks
-lib uinstrument
--macro uinstrument.TraceCalls.hijack("haxe.format.JsonParser")
--macro uinstrument.TraceCalls.hijack("Std")
```

```
$ haxe call_stacks.hxml

$ neko call_stacks.n
CALL Std.__init__
CALL haxe.format.JsonParser.new
CALL haxe.format.JsonParser.parseRec
CALL haxe.format.JsonParser.parseString
CALL haxe.format.JsonParser.parseRec
CALL Std.parseFloat
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 131
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 76
    [2 ommited]
CALL Std.int
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 131
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 76
    [2 ommited]
CallStacks.hx:30: { value => 33.3 }
```

## Advanced instrumentation

More complex or specific instrumentation can be achieved by directly calling
the instrumenter with a custom transformation function.

```
uinstrument.Instrument.hijack(<transform>, <class name>, ?<field name>)
```

## Notes

1. Inline functions are normally ignored; if, however, they are explicitly
   instrumented (as opposed to being inside a class that's being instrumented),
   they will loose their `AInline` access modifier.

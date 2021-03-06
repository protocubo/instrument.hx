# µinstrument.hx
_Micro framework for Haxe instrumentation_

1. _[A visual example](#a-visual-example)_
2. _[Tracing calls and arguments](#tracing-calls-and-arguments)_  
   2.1. _[Debugging database requests](#debugging-database-requests)_
3. _[Timing calls](#timing-calls)_
4. _[Customizing the callbacks](#customizing-the-callbacks)_
5. _[Advanced instrumentation](#advanced-instrumentation)_
6. _[Notes](#notes)_

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
the desired methods to call `uinstrument.TraceCalls.onCalled` at their beginning.

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
should be replaced by `TraceArgs`: this will instead call its `onCalled`
function with an extra `args:Array<{ name:String, value:Dynamic }>` array.

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

Note that `TraceCalls.onCalled` and `TraceArgs.onCalled` are `dynamic`
functions and can be replaced at runtime: see [_Customizing the callbacks:
tracing call stacks_](#customizing-the-callbacks).

### Debugging database requests

Tracing calls and arguments can be used to debug database requests, which can
be particularly helpful when a project uses record-macros.

```hxml
-lib uinstrument
--macro uinstrument.TraceArgs.hijack("sys.db.Sqlite.SqliteConnection", "request")
--macro uinstrument.TraceArgs.hijack("sys.db.Mysql.MysqlConnection", "request")
```

_(You probably do not want to leave this on in production; at the very least
make sure to sanitize the output so no sensitive information ever gets stored
in log files)._

## Timing calls

Similar to call and argument tracing, `uinstrument.TimeCalls.hijack(<class
name>, ?<method name>)` can be used to track the amount of time spent in some
functions of interest.

By default the time spent is traced for every call, but [_customizing the
callback_](#customizing-the-callbacks) by replacing `TimeCalls.onTime` allows
these results to be manipulated freely, for example for aggregation or
plotting.

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

## Customizing the callbacks

As alluded before, it is possible to replace the callbacks from `TraceCalls`,
`TraceArgs` and `TimeCalls` with arbitrary functions.

For a simple example, let us include part of the stack when tracing each call.

```haxe
// CallStacks.hx
import uinstrument.Tools.defaultTrace in itrace;

class CallStacks {
	static function onCalled(?pos:haxe.PosInfos)
	{
		itrace('CALL ${pos.className}.${pos.methodName}', pos);

		// remove onCalled and the instrumented function, and limit the
		// number of call stack items to display to two
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
--macro uinstrument.TraceCalls.hijack("Std")
```

```
$ haxe call_stacks.hxml

$ neko call_stacks.n
CALL Std.__init__
CALL Std.parseFloat
 └╴ Called from /usr/local/share/haxe/std/haxe/format/JsonParser.hx line 145
 └╴ Called from /usr/local/share/haxe/std/haxe/format/JsonParser.hx line 90
    [3 ommited]
CALL Std.int
 └╴ Called from /usr/local/share/haxe/std/haxe/format/JsonParser.hx line 145
 └╴ Called from /usr/local/share/haxe/std/haxe/format/JsonParser.hx line 90
    [3 ommited]
CALL Std.string
 └╴ Called from /usr/local/share/haxe/std/haxe/Log.hx line 34
 └╴ Called from /usr/local/share/haxe/std/haxe/Log.hx line 63
    [2 ommited]
CallStacks.hx:24: { value => 33.3 }
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

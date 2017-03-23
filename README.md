# Instrumentation micro framework

## Tracing calls and arguments

Calls and arguments can be traced easily.  With the default notifiers, the output will look something like:

```
$ ./calls_and_args_example
CALL haxe.Json.parse
CALL Std.parseFloat(x=<33.3>)
```

First, for simple call tracing, it's enough to use `instrument.TraceCalls.hijack(<class name>, ?<method name>)`.
This will adapt the desired methods to call `instrument.TraceCalls.notify` at their beginning.

If, on the other hand, inspection of the arguments is desired, `TraceCalls` should be replaced by `TraceArgs`.
This will instead call its own `notify` function with an extra `args:Array<{ name:String, value:Dynamic }>` array.

Both `notify` functions are `dynamic` and can be replaced at runtime.

## Timing calls

```
$ ./timing_example
TIME 102μs on haxe.Json.parse
```

## A complete example

```haxe
# Basic.hx
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
-lib instrument
--macro instrument.TimeCalls.hijack("haxe.Json", "parse")
--macro instrument.TraceCalls.hijack("haxe.Json")
--macro instrument.TraceArgs.hijack("Std", "parseFloat")
--macro instrument.TraceArgs.hijack("Std", "int")
```

```
$ neko basic.n
CALL haxe.Json.parse
CALL Std.parseFloat(x=<33.3>)
CALL Std.int(x=<33.3>)
TIME 102μs on haxe.Json.parse
Basic.hx:4: { value => 33.3 }
```

## Customizing the callbacks: tracing call stacks

```haxe
# CallStacks.hx
import instrument.Tools.defaultTrace in itrace;

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
		instrument.TraceCalls.onCalled = onCalled;
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}
```

```hxml
# call_stacks.hxml
-neko call_stacks.n
-main CallStacks
-lib instrument
--macro instrument.TraceCalls.hijack("haxe.Json", "parse")
--macro instrument.TraceCalls.hijack("Std")
```

```
$ neko call_stacks.n
CALL Std.__init__
CALL haxe.Json.parse
CALL Std.parseFloat
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 131
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 76
    [4 ommited]
CALL Std.int
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 131
 └╴ Called from /usr/lib/haxe/std/haxe/format/JsonParser.hx line 76
    [4 ommited]
CallStacks.hx:30: { value => 33.3 }
```

## Advanced instrumentation

`instrument.Instrument.hijack(<transform>, <class name>, ?<field name>)`

More complex or specific instrumentation can be achivied by directly calling
the instrumenter with a custom transformation function.

## Notes

 - inline functions are normally ignored; if, however, they are explicitly
   instrumented (as opposed to being inside a class that's being instrumented),
   they will loose their `AInline` access modifier


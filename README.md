# Instrumentation micro framework

## Tracing calls and arguments

Calls and arguments can be traced easily.  With the default notifiers, the output will look something like:

```
$ ./calls_and_args_example
Json.hx:43: CALL haxe.Json.parse
Std.hx:53: CALL Std.parseFloat(x=<33.3>)
```

First, for simple call tracing, it's enough to use `instrument.TraceCalls.hijack(<class name>, ?<method name>)`.
This will adapt the desired methods to call `instrument.TraceCalls.notify` at their beginning.

If, on the other hand, inspection of the arguments is desired, `TraceCalls` should be replaced by `TraceArgs`.
This will instead call its own `notify` function with an extra `args:Array<{ name:String, value:Dynamic }>` array.

Both `notify` functions are `dynamic` and can be replaced at runtime.

## Timing calls

```
$ ./timing_example
Json.hx:44: TIME 81μs on haxe.Json.parse
```

## A complete example

```
# Complete.hx
class Complete {
	static function main()
	{
		trace(haxe.Json.parse('{ "value" : 33.3 }'));
	}
}
```

```
# complete.hxml
-neko complete.n
-main Complete
-lib instrument
--macro instrument.TimeCalls.hijack("haxe.Json", "parse")
--macro instrument.TraceCalls.hijack("haxe.Json")
--macro instrument.TraceArgs.hijack("Std", "parseFloat")
--macro instrument.TraceArgs.hijack("Std", "int")
-D dump=pretty
```

```
$ haxe complete.hxml
/home/jonas/Code/instrument.hx/lib/instrument/Instrument.hx:26: characters 71-73 : Warning : Removing AInline access from haxe.Json.parse
```

```
$ neko complete.n
Json.hx:43: CALL haxe.Json.parse
Std.hx:53: CALL Std.parseFloat(x=<33.3>)
Std.hx:37: CALL Std.int(x=<33.3>)
Json.hx:44: TIME 81μs on haxe.Json.parse
Complete.hx:4: { value => 33.3 }
```

## Advanced instrumentation

`instrument.Instrument.hijack(<transform>, <class name>, ?<field name>)`

More complex or specific instrumentation can be achivied by directly calling
the instrumenter with a custom transformation function.

## Notes

 - inline functions are normally ignored; if, however, they are explicitly
   instrumented (as opposed to being inside a class that's being instrumented),
   they will loose their `AInline` access modifier


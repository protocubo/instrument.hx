# Instrumentation micro framework

## Tracing calls: `instrument.TraceCalls.hijack(<class name>, ?<field name>)`

```
# build.hxml
[...]
--macro instrument.TraceCalls.hijack("SomeLocks")
--macro instrument.TraceCalls.hijack("SomeLocks", "new")
```

## Timing calls: `instrument.TraceCalls.hijack(<class name>, ?<field name>)`

```
# build.hxml
[...]
--macro instrument.TraceCalls.hijack("SomeLocks")
--macro instrument.TraceCalls.hijack("SomeLocks", "new")
```

## Generic instrumentation: `instrument.Instrument.hijack(<transform>, <class name>, ?<field name>)`

# build.hxml
[...]
--macro instrument.Instrument.hijack(custom, "SomeLocks, "new")
```


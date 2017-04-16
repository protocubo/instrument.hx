import utest.Assert;

class Test {
	var onCalledCopy = instrument.TraceCalls.onCalled;
	var onTimedCopy = instrument.TimeCalls.onTimed;
	var onCalled2Copy = instrument.TraceArgs.onCalled;

	function new() {}

	public function setup()
	{
		instrument.TraceCalls.onCalled =
			function (?pos:haxe.PosInfos)
			{
				if (pos.className != "SomeLocks")
					onCalledCopy(pos);
			}
		instrument.TimeCalls.onTimed =
			function (st, fi, ?pos:haxe.PosInfos)
			{
				if (pos.className != "SomeLocks")
					onTimedCopy(st, fi, pos);
			}
		instrument.TraceArgs.onCalled =
			function (args, ?pos:haxe.PosInfos)
			{
				if (pos.className != "SomeLocks")
					onCalled2Copy(args, pos);
			}
	}

	public function teardown()
	{
		instrument.TraceCalls.onCalled = onCalledCopy;
		instrument.TimeCalls.onTimed = onTimedCopy;
		instrument.TraceArgs.onCalled = onCalled2Copy;
	}

	public function test_001_trace_calls()
	{
		var calls = [];
		instrument.TraceCalls.onCalled =
			function (?pos)
			{
				if (pos.className != "SomeLocks" && pos.className.indexOf("SubType") < 0)
					onCalledCopy(pos);
				else
					calls.push('${pos.className}.${pos.methodName}');
			}

		var ls = SomeLocks.create(4);
		ls.acquire(2);
		ls.release(2);
		ls.acquire(2);

		SomeLocks.SubType.foo();

		Assert.same( [
				"SomeLocks.create",
				"SomeLocks.new",
				"SomeLocks.acquire",
				"SomeLocks.release",
				"SomeLocks.acquire",
				"SubType.foo",
				"_SomeLocks.PrivSubType.bar"
			], calls);
	}

	public function test_002_time_calls()
	{
		var times = [];
		instrument.TimeCalls.onTimed =
			function (start, finish, ?pos)
			{
				if (pos.className != "SomeLocks")
					onTimedCopy(start, finish, pos);
				else
					times.push({ method:pos.methodName, time:(finish - start) });
			}

		var ls = SomeLocks.create(1000);
		ls.acquire(314);
		ls.release(314);
		ls.acquire(314);
		ls.releaseAll();
		ls.acquire(750);
		ls.acquire(314);

		Assert.equals(2 + 3 + 1001 + 2, times.length);
		Assert.equals("releaseAll", times[times.length - 3].method);
		Assert.equals("release", times[3].method);
		Assert.isTrue(times[times.length - 3].time >= times[3].time*100/2);
	}

	public function test_003_time_auto_scale()
	{
		// all available divisors
		Assert.equals("min", instrument.TimeCalls.autoScale(60).symbol);  // unstable: trigger for min
		Assert.equals("s", instrument.TimeCalls.autoScale(59).symbol);
		Assert.equals("s", instrument.TimeCalls.autoScale(1).symbol);
		Assert.equals("ms", instrument.TimeCalls.autoScale(0.999).symbol);
		Assert.equals("ms", instrument.TimeCalls.autoScale(0.001).symbol);
		Assert.equals("μs", instrument.TimeCalls.autoScale(0.000999).symbol);
		Assert.equals("μs", instrument.TimeCalls.autoScale(0.000001).symbol);
		Assert.equals("ns", instrument.TimeCalls.autoScale(0.000000999).symbol);
		Assert.equals("ns", instrument.TimeCalls.autoScale(0.000000001).symbol);
		Assert.equals("ns", instrument.TimeCalls.autoScale(0.000000000001).symbol);  // unstable: inexistance of p[ico]

		// best results considering use case is Math.round(t*divisor)
		Assert.equals("s", instrument.TimeCalls.autoScale(59.4).symbol);  // unstable: trigger for min
		Assert.equals("min", instrument.TimeCalls.autoScale(59.6).symbol);  // unstable: trigger for min
		Assert.equals("μs", instrument.TimeCalls.autoScale(0.0009994).symbol);
		Assert.equals("ms", instrument.TimeCalls.autoScale(0.0009996).symbol);
	}

	public function test_004_trace_call_args()
	{
		var calls = [];
		instrument.TraceArgs.onCalled =
			function (args, ?pos)
			{
				if (pos.className != "SomeLocks") {
					onCalled2Copy(args, pos);
				} else {
					var c = {
						call:'${pos.className}.${pos.methodName}',
						args:args.map(function (i) return i.value)
					};
					calls.push(c);
				}
			}

		var ls = SomeLocks.create(2);
		ls.releaseAll();
		ls.acquire(1);

		Assert.same( [
				{ call:"SomeLocks.create", args:[2] },
				{ call:"SomeLocks.new", args:[2] },
				{ call:"SomeLocks.releaseAll", args:[] },
				{ call:"SomeLocks.release", args:[0] },
				{ call:"SomeLocks.release", args:[1] },
				{ call:"SomeLocks.acquire", args:[1] }
			], calls);
	}

	public function test_005_sqlite()
	{
		var calls = [];
		instrument.TimeCalls.onTimed =
			function (start, finish, ?pos)
			{
				if (pos.className.indexOf("Sqlite") < 0)
					onTimedCopy(start, finish, pos);
				else
					calls.push('${pos.className}.${pos.methodName}');
			}

		var cnx = sys.db.Sqlite.open(":memory:");
		cnx.request("SELECT 1");
		cnx.close();

		Assert.same( [
				"sys.db.Sqlite.open",
				"sys.db._Sqlite.SqliteConnection.request",
				"sys.db._Sqlite.SqliteConnection.close"
			], calls);
	}

	static function main()
	{
		var r = new utest.Runner();
		r.addCase(new Test());
		utest.ui.Report.create(r);
		r.run();
	}
}


import utest.Assert;

class Test {
	var onCalledCopy:?haxe.PosInfos->Void;
	var onTimedCopy:Float->Float->?haxe.PosInfos->Void;

	function new() {}

	public function setup()
	{
		onCalledCopy = instrument.TraceCalls.onCalled;
		onTimedCopy = instrument.TimeCalls.onTimed;
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
	}

	public function teardown()
	{
		instrument.TraceCalls.onCalled = onCalledCopy;
		instrument.TimeCalls.onTimed = onTimedCopy;
	}

	public function test_001_trace_calls()
	{
		var calls = [];
		instrument.TraceCalls.onCalled =
			function (?pos)
			{
				if (pos.className != "SomeLocks")
					onCalledCopy(pos);
				else
					calls.push('${pos.className}.${pos.methodName}');
			}

		var ls = SomeLocks.create(10);
		ls.acquire(3);
		ls.release(3);
		ls.acquire(3);

		Assert.same( [
				"SomeLocks.create",
				"SomeLocks.new",
				"SomeLocks.acquire",
				"SomeLocks.release",
				"SomeLocks.acquire"
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

		var ls = SomeLocks.create(100);
		ls.acquire(33);
		ls.release(33);
		ls.acquire(33);
		ls.releaseAll();
		ls.acquire(75);
		ls.acquire(33);

		Assert.equals(2 + 3 + 101 + 2, times.length);
		Assert.equals("releaseAll", times[times.length - 3].method);
		Assert.equals("release", times[3].method);
		Assert.isTrue(times[times.length - 3].time >= times[3].time*100/2);
	}

	static function main()
	{
		var r = new utest.Runner();
		r.addCase(new Test());
		utest.ui.Report.create(r);
		r.run();
	}
}


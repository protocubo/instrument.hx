import utest.Assert;

class Test {
	function new() {}

	public function test_001_trace_calls()
	{
		Assert.pass();
	}

	public function test_002_time_calls()
	{
		Assert.pass();
	}

	public function test_003_generic_instrumentation()
	{
		Assert.pass();
	}

	static function main()
	{
		var r = new utest.Runner();
		r.addCase(new Test());
		utest.ui.Report.create(r);
		r.run();
	}
}


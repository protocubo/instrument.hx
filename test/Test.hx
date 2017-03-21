import utest.Assert;

class Test {
	function new() {}

	public function test_001_test_htrace()
	{
		trace("Std::int", Std.int(1.1));
		trace("Sys::systemName", Sys.systemName());
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


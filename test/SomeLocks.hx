private class PrivSubType {
	public static function bar() {}
}

class SubType {
	public static function foo()
		PrivSubType.bar();
}

class SomeLocks {
	var ls:Array<Int>;
	var size:Int;

	function new(size)
	{
		this.size = size;
		if (size == 0) return;  // make sure that empty returns don't break
		this.ls = [ for (i in 0...size) 0 ];
	}

	public function release(i:Int)
	{
		if (i < 0 || i >= size) throw "Out of bounds";
		ls[i]++;
	}

	public function releaseAll()
	{
		for (i in 0...size)
			release(i);
	}

	public function acquire(i:Int):Bool
	{
		if (ls[i] < 1) return false;
		ls[i]--;
		return true;
	}

	public static function create(size)
		return new SomeLocks(size);
}

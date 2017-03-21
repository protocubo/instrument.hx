class SomeLocks {
	var ls:Array<Int>;
	var size:Int;

	function new(size)
	{
		this.size = size;
		this.ls = [ for (i in 0...size) 0 ];
	}

	public function release(i:Int)
		ls[i]++;

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


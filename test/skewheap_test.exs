defmodule SkewheapDocTest do
  use ExUnit.Case
  doctest Skewheap
end

defmodule SkewheapTest do
  use ExUnit.Case
  doctest Skewheap

  test "ordering" do
    skew = Skewheap.new()
    assert Skewheap.empty?(skew)

    size = 100
    nums = Enum.to_list(1..size)
    skew = Enum.reduce(Enum.shuffle(nums), skew, fn n, acc -> Skewheap.put(acc, n) end)

    assert !Skewheap.empty?(skew)
    assert skew.size == size

    {skew, items} = Skewheap.drain(skew)
    assert Skewheap.empty?(skew)
    assert items == nums
  end

  test "peek" do
    skew = Skewheap.new()
    assert is_nil(Skewheap.peek(skew))

    skew = Skewheap.put(skew, 5)
    assert Skewheap.peek(skew) == 5

    skew = Skewheap.put(skew, 7)
    assert Skewheap.peek(skew) == 5

    skew = Skewheap.put(skew, 3)
    assert Skewheap.peek(skew) == 3
  end

  test "merge" do
    a = Enum.reduce(Enum.to_list(1..5), Skewheap.new(), fn n, acc -> Skewheap.put(acc, n) end)
    b = Enum.reduce(Enum.to_list(6..10), Skewheap.new(), fn n, acc -> Skewheap.put(acc, n) end)
    c = Skewheap.merge(a, b)

    assert !Skewheap.empty?(c)
    assert c.size == 10
    {c, items} = Skewheap.drain(c)
    assert Skewheap.empty?(c)
    assert items == Enum.to_list(1..10)
  end
end

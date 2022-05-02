defmodule Skewheap do
  @moduledoc """
  Skewheap - a mergable priority queue

  Skewheaps are a weird sort of priority queue that self-balances over time.
  Their structural depth is not guaranteed and individual operations may vary
  in performance. That said, its _amortized_ performance is roughly O(log n)
  ([source](https://en.wikipedia.org/wiki/Skew_heap)).

  Skewheaps' most interesting characteristic is that they can be _very_ quickly
  merged together non-destructively, creating a new, balanced heap containing
  all elements of the source heaps.

  # Usage
  ```
    s = Skewheap.new()

    # Insert some items
    s = Skewheap.put(s, 10)
    s = Skewheap.put(s, 5)
    s = Skewheap.put(s, 15)

    # Take a peek
    3 == Skewheap.size(s)
    5 == Skewheap.peek(s)

    # Retrieve values
    s, val = Skewheap.take(s) # 5
    s, val = Skewheap.take(s) # 10
    s, val = Skewheap.take(s) # 15

    # Merge heaps
    a = Enum.reduce(Enum.shuffle([1,2,3]), Skewheap.new(), fn n, acc -> Skewheap.put(acc, n) end)
    b = Enum.reduce(Enum.shuffle([4,5,6]), Skewheap.new(), fn n, acc -> Skewheap.put(acc, n) end)
    c = Skewheap.merge(a, b)

    Skewheap.size(c) == 6
    Skewheap.drain(c) == [1,2,3,4,5,6]
  ```
  """

  defmodule Skewnode do
    @moduledoc "An individual node in a Skewheap. This should probably not be used directly."

    defstruct [:payload, left: nil, right: nil]

    @doc "Returns a new node"
    def new(payload, left \\ nil, right \\ nil) do
      %Skewnode{payload: payload, left: left, right: right}
    end

    @doc "Merges two nodes into a new node"
    def merge(a, b) when is_nil(a) and is_nil(b) do nil end
    def merge(a, b) when is_nil(a) do b end
    def merge(a, b) when is_nil(b) do a end
    def merge(a, b) when a.payload > b.payload do merge(b, a) end

    def merge(a, b) do
      Skewnode.new(a.payload, merge(b, a.right), a.left)
    end
  end


  defstruct [size: 0, root: nil]

  @doc """
  Returns a new Skewheap.

  ```
  s = Skewheap.new()
  ```
  
  """
  def new() do
    %Skewheap{}
  end

  @doc """
  True when the Skewheap has no items in it.

  ```
  unless Skewheap.empty?(s) do
    {s, value} = Skewheap.take(s)
  end
  ```
  """
  defmacro empty?(skew) do
    quote do
      (unquote(skew)).size == 0
    end
  end

  @doc "Returns the number of items in the Skewheap."
  def size(skew) do
    skew.size
  end

  @doc """
  Returns the top element of the heap without removing it or nil if empty.

  ```
  value = Skewheap.peak(s)    
  ```
  """
  def peek(skew) when empty?(skew) do
    nil
  end

  def peek(skew) do
    skew.root.payload
  end

  @doc """
  Adds a new element to the heap.

  ```
  s = Skewheap.put(s, 42)
  s = Skewheap.put(s, "fnord")
  ```
  """
  def put(skew, payload) when empty?(skew) do
    %Skewheap{size: 1, root: Skewnode.new(payload)}
  end

  def put(skew, payload) do
    %Skewheap{size: skew.size + 1, root: Skewnode.merge(skew.root, Skewnode.new(payload))}
  end

  @doc """
  Retrieves the top element from the heap or nil if empty.

  ```
  {s, value} = Skewheap.take(s)
  ```
  """
  def take(skew) when empty?(skew) do
    {skew, nil}
  end

  def take(skew) do
    %Skewnode{:payload => payload} = skew.root
    {%Skewheap{size: skew.size - 1, root: Skewnode.merge(skew.root.left, skew.root.right)}, payload}
  end

  @doc """
  Removes all elements from the heap and returns them as a list.

  ```
  {s, list_of_all_values} = Skewheap.drain(s)
  ```
  """
  def drain(skew) when empty?(skew) do
    {skew, []}
  end

  def drain(skew) do
    {skew, payload} = take(skew)
    {skew, rest} = drain(skew)
    {skew, [payload | rest]}
  end

  @doc """
  Merges two skew heaps into a new heap.

  ```
  all_numbers = Skewheap.merge(odss, evens)
  ```
  """
  def merge(a, b) do
    %Skewheap{size: a.size + b.size, root: Skewnode.merge(a.root, b.root)}
  end
end

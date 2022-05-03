defmodule Skewheap do
  @moduledoc """
  Skewheap - a mergable priority queue

  Skewheaps are a fun, weird, priority queue that self-balances over time.
  Their structural depth is not guaranteed and individual operations may vary
  in performance. That said, its _amortized_ performance is roughly O(log n)
  ([source](https://en.wikipedia.org/wiki/Skew_heap)).

  Skewheaps' most interesting characteristic is that they can be _very_ quickly
  merged together non-destructively, creating a new, balanced heap containing
  all elements of the source heaps.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0}, [1,2,3,4,5,6,7,8,9,10]}

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> Skewheap.merge(a, b) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0}, [1,2,3,4,5,6]}

  """

  defmodule Node do
    @moduledoc "An individual node in a Skewheap. This should probably not be used directly."

    defstruct payload: nil, left: nil, right: nil

    @type skewnode :: nil | %Node{
      payload: any(),
      left:    node,
      right:   node,
    }

    @spec new(any(), node, node) :: skewnode
    def new(p, l \\ nil, r \\ nil), do: %Node{payload: p, left: l, right: r}

    @spec merge(skewnode, skewnode) :: skewnode
    def merge(a, b) when is_nil(a) and is_nil(b), do: nil
    def merge(a, b) when is_nil(a),               do: b
    def merge(a, b) when is_nil(b),               do: a
    def merge(a, b) when a.payload > b.payload,   do: merge(b, a)
    def merge(a, b),                              do: %Node{payload: a.payload, left: merge(b, a.right), right: a.left}
  end


  defstruct size: 0, root: nil

  @type skewheap :: %Skewheap{
    size: non_neg_integer(),
    root: Node.skewnode,
  }

  @doc """
  Returns a new Skewheap.

  ## Examples

      iex> Skewheap.new()
      %Skewheap{size: 0, root: nil}
  """
  @spec new() :: skewheap
  def new(), do: %Skewheap{}

  @doc """
  True when the Skewheap has no items in it.

  ## Examples

      iex> Skewheap.new() |> Skewheap.empty?()
      true

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.empty?()
      false
  """
  defmacro empty?(skew) do
    quote do
      (unquote(skew)).size == 0
    end
  end

  @doc """
  Returns the number of items in the Skewheap.

  ## Examples

      iex> Skewheap.new() |> Skewheap.size()
      0

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.size()
      10
  """
  @spec size(skewheap) :: non_neg_integer()
  def size(skew), do: skew.size

  @doc """
  Returns the top element of the heap without removing it or nil if empty.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.peek()
      1
  """
  @spec peek(skewheap) :: any()
  def peek(skew) when empty?(skew), do: nil
  def peek(skew), do: skew.root.payload

  @doc """
  Adds a new element to the heap.

  ## Examples

      iex> s = Skewheap.new()
      iex> s = Skewheap.put(s, 42)
      iex> Skewheap.put(s, "fnord")
      %Skewheap{size: 2, root: %Skewheap.Node{left: %Skewheap.Node{left: nil, payload: "fnord", right: nil}, payload: 42, right: nil}}
  """
  @spec put(skewheap, any()) :: skewheap
  def put(skew, payload) when empty?(skew), do: %Skewheap{size: 1, root: Node.new(payload)}
  def put(skew, payload), do: %Skewheap{size: skew.size + 1, root: Node.merge(skew.root, Node.new(payload))}

  @doc """
  Retrieves the top element from the heap or nil if empty.

  ## Examples

      iex> [1,2,3] |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.take()
      {%Skewheap{root: %Skewheap.Node{left: %Skewheap.Node{left: nil, payload: 3, right: nil}, payload: 2, right: nil}, size: 2}, 1}
  """
  @spec take(skewheap) :: {skewheap, any()}
  def take(skew) when empty?(skew), do: {skew, nil}
  def take(skew) do
    %Node{:payload => payload} = skew.root
    {%Skewheap{size: skew.size - 1, root: Node.merge(skew.root.left, skew.root.right)}, payload}
  end

  @doc """
  Removes all elements from the heap and returns them as a list.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0}, [1,2,3,4,5,6,7,8,9,10]}
  """
  @spec drain(skewheap) :: {skewheap, [any()]}
  def drain(skew) when empty?(skew), do: {skew, []}
  def drain(skew) do
    {skew, payload} = take(skew)
    {skew, rest} = drain(skew)
    {skew, [payload | rest]}
  end

  @doc """
  Merges two skew heaps into a new heap.

  ## Examples

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> Skewheap.merge(a, b) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0}, [1,2,3,4,5,6]}
  """
  @spec merge(skewheap, skewheap) :: skewheap
  def merge(a, b) do
    %Skewheap{
      size: a.size + b.size,
      root: Node.merge(a.root, b.root),
    }
  end
end

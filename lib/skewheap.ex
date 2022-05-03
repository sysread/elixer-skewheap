defmodule Skewheap do
  @moduledoc """
  Skewheap - a mergable priority queue

  Skewheaps are fun, weird, priority queues that self-balance over time.
  Their structural depth is not guaranteed and individual operations may vary
  in performance. That said, its _amortized_ performance is roughly O(log n)
  ([source](https://en.wikipedia.org/wiki/Skew_heap)).

  Skewheaps' most interesting characteristic is that they can be _very_ quickly
  merged together non-destructively, creating a new, balanced heap containing
  all elements of the source heaps.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0, sorter: &:erlang."=<"/2}, [1,2,3,4,5,6,7,8,9,10]}

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      iex> Skewheap.merge(a, b) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0, sorter: &:erlang."=<"/2}, [1,2,3,4,5,6]}

  """

  defmodule Node do
    @moduledoc "An individual node in a Skewheap. This should probably not be used directly."

    defstruct payload: nil, left: nil, right: nil

    @type skewnode :: nil | %Node{
      payload: any(),
      left:    node,
      right:   node,
    }

    @type sorter :: (any(), any() -> boolean())

    @spec new(any(), node, node) :: skewnode
    def new(p, l \\ nil, r \\ nil), do: %Node{payload: p, left: l, right: r}

    @spec merge(sorter, skewnode, skewnode) :: skewnode
    def merge(_, a, b) when is_nil(a) and is_nil(b), do: nil
    def merge(_, a, b) when is_nil(a),               do: b
    def merge(_, a, b) when is_nil(b),               do: a

    def merge(lte, a, b) do
      if lte.(a.payload, b.payload) do
        %Node{payload: a.payload, left: merge(lte, b, a.right), right: a.left}
      else
        merge(lte, b, a)
      end
    end
  end


  defstruct size: 0, root: nil, sorter: nil

  @type sorter :: (any(), any() -> boolean())

  @type skewheap :: %Skewheap{
    size:   non_neg_integer(),
    root:   Node.skewnode,
    sorter: sorter,
  }

  @doc """
  Returns a new Skewheap.

  ## Examples

      iex> Skewheap.new()
      %Skewheap{size: 0, root: nil, sorter: &:erlang."=<"/2}
  """
  @spec new() :: skewheap
  def new(), do: %Skewheap{sorter: &<=/2}

  @spec new(sorter) :: skewheap
  def new(sorter), do: %Skewheap{sorter: sorter}

  defp merge_nodes(skew, a, b), do: Node.merge(skew.sorter, a, b)

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
      %Skewheap{size: 2, sorter: &:erlang."=<"/2, root: %Skewheap.Node{left: %Skewheap.Node{left: nil, payload: "fnord", right: nil}, payload: 42, right: nil}}
  """
  @spec put(skewheap, any()) :: skewheap
  def put(skew, payload) when empty?(skew) do
    %Skewheap{
      size:   1,
      root:   Node.new(payload),
      sorter: skew.sorter,
    }
  end

  def put(skew, payload) do
    %Skewheap{
      size:   skew.size + 1,
      root:   merge_nodes(skew, skew.root, Node.new(payload)),
      sorter: skew.sorter
    }
  end

  @doc """
  Retrieves the top element from the heap or nil if empty.

  ## Examples

      iex> [1,2,3] |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.take()
      {%Skewheap{size: 2, sorter: &:erlang."=<"/2, root: %Skewheap.Node{left: %Skewheap.Node{left: nil, payload: 3, right: nil}, payload: 2, right: nil}}, 1}
  """
  @spec take(skewheap) :: {skewheap, any()}
  def take(skew) when empty?(skew), do: {skew, nil}
  def take(skew) do
    %Node{:payload => payload} = skew.root
    {
      %Skewheap{
        size:   skew.size - 1,
        root:   merge_nodes(skew, skew.root.left, skew.root.right),
        sorter: skew.sorter,
      },
      payload,
    }
  end

  @doc """
  Removes all elements from the heap and returns them as a list.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      {%Skewheap{root: nil, size: 0, sorter: &:erlang."=<"/2}, [1,2,3,4,5,6,7,8,9,10]}
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
      {%Skewheap{root: nil, size: 0, sorter: &:erlang."=<"/2}, [1,2,3,4,5,6]}
  """
  @spec merge(skewheap, skewheap) :: skewheap
  def merge(a, b) do
    %Skewheap{
      size:   a.size + b.size,
      root:   merge_nodes(a, a.root, b.root),
      sorter: a.sorter,
    }
  end
end

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
      {%Skewheap{root: :leaf, size: 0, sorter: &:erlang."=<"/2}, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> Skewheap.merge(a, b) |> Skewheap.drain()
      {%Skewheap{root: :leaf, size: 0, sorter: &:erlang."=<"/2}, [1, 2, 3, 4, 5, 6]}

  """
  @type skewnode :: :leaf | {any(), skewnode, skewnode}

  @spec skewnode(any(), skewnode, skewnode) :: skewnode
  defp skewnode(p, l \\ :leaf, r \\ :leaf), do: {p, l, r}

  defmacrop leaf?(node) do
    quote do
      (unquote node) == :leaf
    end
  end

  defmacrop payload(node) do
    quote do
      elem((unquote node), 0)
    end
  end

  defmacrop left(node) do
    quote do
      elem((unquote node), 1)
    end
  end

  defmacrop right(node) do
    quote do
      elem((unquote node), 2)
    end
  end

  @spec merge_nodes(skewheap, skewnode, skewnode) :: skewnode
  defp merge_nodes(skew, a, b) do
    cond do
      leaf?(a) and leaf?(b)                -> :leaf
      leaf?(a)                             -> b
      leaf?(b)                             -> a
      skew.sorter.(payload(b), payload(a)) -> merge_nodes(skew, b, a)
      true                                 -> skewnode(payload(a), merge_nodes(skew, b, right(a)), left(a))
    end
  end


  defstruct size: 0, root: :leaf, sorter: nil

  @type sorter :: (any(), any() -> boolean())

  @type skewheap :: %Skewheap{
    size:   non_neg_integer(),
    root:   skewnode,
    sorter: sorter,
  }

  @doc """
  Returns a new Skewheap.

  ## Examples

      iex> Skewheap.new()
      %Skewheap{size: 0, root: :leaf, sorter: &:erlang."=<"/2}
  """
  @spec new() :: skewheap
  def new(), do: %Skewheap{sorter: &<=/2}

  @spec new(sorter) :: skewheap
  def new(sorter), do: %Skewheap{sorter: sorter}

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
      (unquote skew).size == 0
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
  def peek(skew), do: payload(skew.root)

  @doc """
  Adds a new element to the heap.

  ## Examples

      iex> s = Skewheap.new()
      ...> s = Skewheap.put(s, 42)
      ...> Skewheap.put(s, "fnord")
      ...> Skewheap.peek(s)
      42
  """
  @spec put(skewheap, any()) :: skewheap
  def put(skew, payload) when empty?(skew) do
    %Skewheap{
      size:   1,
      root:   skewnode(payload),
      sorter: skew.sorter,
    }
  end

  def put(skew, payload) do
    %Skewheap{
      size:   skew.size + 1,
      root:   merge_nodes(skew, skew.root, skewnode(payload)),
      sorter: skew.sorter
    }
  end

  @doc """
  Retrieves the top element from the heap or nil if empty.

  ## Examples

      iex> {s, v} = [1,2,3] |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.take()
      ...> {v, Skewheap.size(s)}
      {1, 2}
  """
  @spec take(skewheap) :: {skewheap, any()}
  def take(skew) when empty?(skew), do: {skew, nil}
  def take(skew) do
    {payload, _, _} = skew.root
    {
      %Skewheap{
        size:   skew.size - 1,
        root:   merge_nodes(skew, left(skew.root), right(skew.root)),
        sorter: skew.sorter,
      },
      payload,
    }
  end

  @doc """
  Removes all elements from the heap and returns them as a list.

  ## Examples

      iex> {_, items} = 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
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
      ...> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> {_, items} = Skewheap.merge(a, b) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6]
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

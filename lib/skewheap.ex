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

      iex> {_skew, items} = 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> {_skew, items} = Skewheap.merge(a, b) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6]

  ## Protocols

  By default, the following protocols are implemented for `Skewheap`.

    * `Collectable`
    * `Enumerable`
    * `Inspect`

  """
  #-----------------------------------------------------------------------------
  # Node type
  #-----------------------------------------------------------------------------
  @typep skewnode :: :leaf | {any(), skewnode, skewnode}
  defmacrop skewnode(p, l \\ :leaf, r \\ :leaf) do
    quote do
      {
        unquote(p),
        unquote(l),
        unquote(r),
      }
    end
  end

  # Accessors and predicates
  defmacrop payload(node), do: quote do: elem((unquote node), 0)
  defmacrop left(node),    do: quote do: elem((unquote node), 1)
  defmacrop right(node),   do: quote do: elem((unquote node), 2)
  defmacrop leaf?(node),   do: quote do: (unquote node) == :leaf

  @spec merge_nodes(t, skewnode, skewnode) :: skewnode
  defp merge_nodes(_, :leaf, :leaf), do: :leaf
  defp merge_nodes(_, :leaf, b),     do: b
  defp merge_nodes(_, a, :leaf),     do: a
  defp merge_nodes(skew, a, b) do
    if skew.sorter.(payload(b), payload(a)) do
      merge_nodes skew, b, a
    else
      skewnode payload(a), merge_nodes(skew, b, right(a)), left(a)
    end
  end

  @spec find(sorter, skewnode, any()) :: boolean()
  defp find(_, :leaf, _), do: false
  defp find(_, {element, _, _}, element), do: true
  defp find(sorter, {_, left, right}, element) do
    keep_left = !leaf?(left) && sorter.(payload(left), element)
    keep_right = !leaf?(right) && sorter.(payload(right), element)
    case {keep_left, keep_right} do
      {true,  true}   -> find(sorter, left, element) || find(sorter, right, element)
      {true,  false}  -> find(sorter, left, element)
      {false, true}   -> find(sorter, right, element)
      {false, false}  -> false
    end
  end

  #-----------------------------------------------------------------------------
  # Skewheap type implementation
  #-----------------------------------------------------------------------------
  defstruct size: 0, root: :leaf, sorter: &<=/2

  @type t :: %__MODULE__{
    size:   non_neg_integer(),
    root:   skewnode,
    sorter: sorter,
  }

  @typep sorter :: (any(), any() -> boolean())

  #-----------------------------------------------------------------------------
  # Skewheap API
  #-----------------------------------------------------------------------------
  @doc """
  True when the Skewheap has no items in it.

  ## Examples

      iex> Skewheap.new() |> Skewheap.empty?()
      true

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.empty?()
      false
  """
  defmacro empty?(skew), do: quote do: (unquote skew).size == 0


  @doc """
  Returns a new Skewheap.

  ## Examples

      iex> Skewheap.new() |> Skewheap.size()
      0

      iex> Skewheap.new() |> Skewheap.empty?()
      true
  """
  @spec new(sorter) :: t
  def new(sorter \\ &<=/2), do: %Skewheap{sorter: sorter}


  @doc """
  Returns the number of items in the Skewheap.

  ## Examples

      iex> Skewheap.new() |> Skewheap.size()
      0

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.size()
      10
  """
  @spec size(t) :: non_neg_integer()
  def size(skew), do: skew.size


  @doc """
  Returns the top element of the heap without removing it or `:nothing` if empty.

  ## Examples

      iex> 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.peek()
      1

      iex> Skewheap.new() |> Skewheap.peek()
      :nothing
  """
  @spec peek(t) :: any()
  def peek(skew) when empty?(skew), do: :nothing
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
  @spec put(t, any()) :: t
  def put(skew, payload) do
    %Skewheap{
      size:   skew.size + 1,
      root:   merge_nodes(skew, skew.root, skewnode(payload)),
      sorter: skew.sorter
    }
  end


  @doc """
  Fills the heap with a list of items.

  ## Examples

    iex> {_skew, items} = Skewheap.fill(Skewheap.new(), 1..5 |> Enum.shuffle()) |> Skewheap.drain()
    ...> items
    [1, 2, 3, 4, 5]
  """
  @spec fill(t, [any()]) :: t
  def fill(skew, [car | cdr]), do: fill(put(skew, car), cdr)
  def fill(skew, _),           do: skew


  @doc """
  Retrieves the top element from the heap or `:nothing` if empty.

  ## Examples

      iex> {_skew, value} = Skewheap.new() |> Skewheap.take()
      ...> value
      :nothing

      iex> {skew, value} = [1,2,3] |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.take()
      ...> {value, Skewheap.size(skew)}
      {1, 2}
  """
  @spec take(t) :: {t, any()}
  def take(skew) when empty?(skew), do: {skew, :nothing}
  def take(skew) do
    {
      %Skewheap{
        size:   skew.size - 1,
        root:   merge_nodes(skew, left(skew.root), right(skew.root)),
        sorter: skew.sorter,
      },
      payload(skew.root),
    }
  end


  @doc """
  Removes all elements from the heap and returns them as a list.

  ## Examples

      iex> {_skew, items} = 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  """
  @spec drain(t) :: {t, [any()]}
  def drain(skew), do: drain(skew, size(skew))


  @doc """
  Removes up to `count` elements from the heap and returns them as a list.

  ## Examples

      iex> {_skew, items} = 1..5 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5]

      iex> {_skew, items} = 1..5 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain(3)
      ...> items
      [1, 2, 3]

      iex> {_skew, items} = 1..5 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain(5)
      ...> items
      [1, 2, 3, 4, 5]
  """
  @spec drain(t, non_neg_integer()) :: {t, [any()]}
  def drain(skew, count), do: drain(skew, count, [])

  @spec drain(t, non_neg_integer(), [any()]) :: {t, [any()]}
  def drain(skew, 0, acc) do
    {skew, Enum.reverse(acc)}
  end

  def drain(skew, count, acc) do
    {skew, payload} = take(skew)
    drain(skew, count - 1, [payload | acc])
  end


  @doc """
  Merges two skew heaps into a new heap.

  ## Examples

      iex> a = 1..3 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> b = 4..6 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> {_skew, items} = Skewheap.merge(a, b) |> Skewheap.drain()
      ...> items
      [1, 2, 3, 4, 5, 6]
  """
  @spec merge(t, t) :: t
  def merge(a, b) do
    %Skewheap{
      size:   a.size + b.size,
      root:   merge_nodes(a, a.root, b.root),
      sorter: a.sorter,
    }
  end


  @doc """
  Returns true if `element` is present in the skewheap. Note that this requires
  a depth first search of the binary heap structure.

  ## Examples

      iex> s = 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> Skewheap.member?(s, 5)
      true

      iex> s = 1..10 |> Enum.shuffle() |> Enum.into(Skewheap.new())
      ...> Skewheap.member?(s, 15)
      false

      iex> Skewheap.member?(Skewheap.new(), 42)
      false
  """
  @spec member?(t, any()) :: boolean()
  def member?(skew, element), do: find(skew.sorter, skew.root, element)
end

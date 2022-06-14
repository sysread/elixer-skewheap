defimpl Enumerable, for: Skewheap do
  @moduledoc """
  Implements `Collectable` for `Skewheap`.
  """

  @doc """
  Returns the number of elements in the heap. 

  ## Examples

      iex> Skewheap.new() |> Enum.count()
      0

      iex> 1..500 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Enum.count()
      500
  """
  @spec count(Skewheap) :: {:ok, non_neg_integer()} | {:error, module()}
  def count(skew), do: {:ok, Skewheap.size(skew)}

  @doc """
  Returns true if `element` exists within the heap. Note that this is a fairly
  slow op, requiring a full traversal of the tree.

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
  @spec member?(Skewheap, term()) :: {:ok, boolean()} | {:error, module()}
  def member?(skew, element), do: {:ok, Skewheap.member?(skew, element)}

  @doc """
  Falls back to the default implementation based on `Enum.reduce`.
  """
  @spec slice(Skewheap) :: {:ok, size :: non_neg_integer(), Enum.slicing_fun()} | {:error, module()}
  def slice(_), do: {:error, __MODULE__}

  @doc """
  Applies a function to each element (and an accumulator) in order until a
  single value remains.

  ## Examples

      iex> Enum.reduce(1..4 |> Enum.shuffle() |> Enum.into(Skewheap.new()), &+/2)
      10
  """
  @spec reduce(Skewheap, Enum.acc(), Enum.reducer()) :: Enum.result()
  def reduce(_, {:halt, acc}, _),                   do: {:halted, acc}
  def reduce(skew, {:suspend, acc}, fun),           do: {:suspended, acc, &reduce(skew, &1, fun)}
  def reduce(%Skewheap{size: 0}, {:cont, acc}, _),  do: {:done, acc}
  def reduce(skew, {:cont, acc}, fun) do
    {skew, value} = Skewheap.take(skew)
    reduce(skew, fun.(value, acc), fun)
  end
end

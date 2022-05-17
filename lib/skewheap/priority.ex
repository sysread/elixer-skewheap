defprotocol Skewheap.Priority do
  @moduledoc """
  Skewheap.Priority - a standard way to prioritize values within a Skewheap

  ## Examples

  The default, pre-defined min-heap functionality for `Skewheap` is
  provided by the implementation of `Skewheap.Priority` for `Integer`.

      defimpl Skewheap.Priority, for: Integer do
        def has_priority(a, b), do: a <= b
      end

  """

  @doc """
  Returns `true` if the first argument should be prioritized ahead of the
  second argument.
  """
  @spec has_priority(t, t) :: boolean
  def has_priority(a, b)
end


defimpl Skewheap.Priority, for: Integer do
  @moduledoc """
  Implements `Skewheap.Priority` for `Integer`, providing the default min-sort
  functionality of a `Skewheap`.
  """

  @doc """
  Orders lower numbers ahead of higher numbers, providing a stable sort for
  numbers within a `Skewheap`.

  ## Examples

      iex> {_, nums} = 1..4 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.drain()
      ...> nums
      [1, 2, 3, 4]
  """
  def has_priority(a, b), do: a <= b
end

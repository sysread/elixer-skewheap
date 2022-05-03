# Stolen from: https://gitlab.com/jimsy/heap/-/blob/main/lib/heap/collectable.ex
defimpl Collectable, for: Skewheap do
  @moduledoc """
  Implements `Collectable` for `Skewheap`.
  """

  @doc """
  Collect an enumerable into a skew heap.

  ## Examples

      iex> 1..500 |> Enum.shuffle() |> Enum.into(Skewheap.new()) |> Skewheap.peek()
      1
  """
  @spec into(Skewheap.skewheap) :: {term(), (term(), Collectable.command() -> Skewheap.skewheap | term())}
  def into(skewheap) do
    {skewheap,
     fn
       s, {:cont, v} -> Skewheap.put(s, v)
       s, :done -> s
       _, :halt -> :ok
     end}
  end
end

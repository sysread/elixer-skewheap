# Adapted from: https://gitlab.com/jimsy/heap/-/blob/main/lib/heap/collectable.ex
defimpl Inspect, for: Skewheap do
  import Inspect.Algebra

  @moduledoc """
  Implements `Inspect` for `Skewheap`.
  """

  @doc """
  Generates a list-style representation of the skewheap.

  ## Examples

      iex> 1..4 |> Enum.into(Skewheap.new()) |> inspect
      "#Skewheap<[1, 2, 3, 4]>"
  """
  @spec inspect(Skewheap.skewheap, Inspect.Opts.t()) :: Inspect.Algebra.t()
  def inspect(s, opts) do
    {_, items} = Skewheap.drain(s)
    concat(["#Skewheap<", to_doc(items, opts), ">"])
  end
end

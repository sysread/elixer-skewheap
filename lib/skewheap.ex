defmodule Skewheap do
  defmodule Node do
    defstruct [:value, left: nil, right: nil]

    def new(value, left \\ nil, right \\ nil) do
      %Node{value: value, left: left, right: right}
    end

    def merge(a, b) when is_nil(a) and is_nil(b) do nil end
    def merge(a, b) when is_nil(a) do b end
    def merge(a, b) when is_nil(b) do a end
    def merge(a, b) when a.value > b.value do merge(b, a) end

    def merge(a, b) do
      Node.new(a.value, merge(b, a.right), a.left)
    end
  end

  defstruct [size: 0, root: nil]

  def new() do
    %Skewheap{}
  end

  defmacro empty?(skew) do
    quote do
      (unquote(skew)).size == 0
    end
  end

  def peek(skew) when empty?(skew) do
    nil
  end

  def peek(skew) do
    skew.root.value
  end

  def put(skew, value) when empty?(skew) do
    %Skewheap{size: 1, root: Node.new(value)}
  end

  def put(skew, value) do
    %Skewheap{size: skew.size + 1, root: Node.merge(skew.root, Node.new(value))}
  end

  def take(skew) when empty?(skew) do
    {skew, nil}
  end

  def take(skew) do
    %Node{:value => value} = skew.root
    {%Skewheap{size: skew.size - 1, root: Node.merge(skew.root.left, skew.root.right)}, value}
  end

  def drain(skew) when empty?(skew) do
    {skew, []}
  end

  def drain(skew) do
    {skew, value} = take(skew)
    {skew, rest} = drain(skew)
    {skew, [value | rest]}
  end

  def merge(a, b) do
    %Skewheap{size: a.size + b.size, root: Node.merge(a.root, b.root)}
  end
end

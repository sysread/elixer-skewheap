require Benchee
require Skewheap

nums = fn n -> Enum.to_list(1..n) |> Enum.shuffle() end

Benchee.run(
  %{
    "fill" => fn input -> Skewheap.fill(Skewheap.new(), input) end,
  },
  inputs: %{
    100     => nums.(100),
    1_000   => nums.(1_000),
    10_000  => nums.(10_000),
  },
  time: 5,
  profile_after: true
)

Benchee.run(
  %{
    "fill/drain" => fn input -> Skewheap.fill(Skewheap.new(), input) |> Skewheap.drain() end,
  },
  inputs: %{
    100     => nums.(100),
    1_000   => nums.(1_000),
    10_000  => nums.(10_000),
  },
  time: 5,
  profile_after: true
)

# Skewheap

![tests](https://github.com/sysread/elixer-skewheap/workflows/Elixir%20CI/badge.svg)

Skewheaps are fun, weird, priority queues that self-balance over time. Their
structural depth is not guaranteed and individual operations may vary in
performance. That said, its _amortized_ performance is roughly O(log n)
([source](https://en.wikipedia.org/wiki/Skew_heap)).

Skewheaps' most interesting characteristic is that they can be _very_ quickly
merged together non-destructively, creating a new, balanced heap containing all
elements of the source heaps.

See [Skew_heap](https://en.wikipedia.org/wiki/Skew_heap) on Wikipedia.

## Installation

1. Add [skewheap](https://hex.pm/packages/skewheap) to your project's dependencies
```elixir
def deps do
  [{:skewheap, "~> 0.5.1"}]
end
```
2. Install
```
$ mix deps.get
```

## Documentation

API documentation available on <https://hexdocs.pm/skewheap>.

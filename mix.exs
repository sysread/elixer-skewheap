defmodule Skewheap.MixProject do
  use Mix.Project

  def project do
    [
      app:             :skewheap,
      version:         "0.1.0",
      elixir:          "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps:            deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "A skewheap is a fun, weird, priority queue that self-balance over time."
  end

  def package do
    [
      maintainers: ["Jeff Ober <sysread@fastmail.fm>"],
      licenses:    ["MIT"],
      links:       %{
        "Repository" => "https://github.com/sysread/elixir-skewheap",
        "Docs"       => "https://hexdocs.pm/skewheap"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
    ]
  end
end

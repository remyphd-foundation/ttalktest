defmodule Ttalktest.MixProject do
  use Mix.Project

  def project do
    [
      app: :ttalktest,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TurtleTalkTest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:bandit, "~> 0.6"},
      {:websock_adapter, "~> 0.5"},
      {:jason, "~> 1.2"},
    ]
  end
end

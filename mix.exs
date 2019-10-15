defmodule ActiveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :ax,
      version: "1.0.0",
      elixir: "~> 1.8",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ActiveEx, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:fs, "~> 3.4"}
    ]
  end
end

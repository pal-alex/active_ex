defmodule ActiveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :active_ex,
      version: "0.1.0",
      elixir: "~> 1.8",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ActiveEx.Supervisor, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fs, git: "https://github.com/pal-alex/fs.git", override: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

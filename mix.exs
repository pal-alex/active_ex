defmodule ActiveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :active_ex,
      version: "1.0.0",
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      mod: {ActiveEx, []},
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      licenses: ["ISC"],
      maintainers: ["pal-alex"],
      name: :active_ex,
      links: %{"GitHub" => "https://github.com/pal-alex/active_ex"}
    ]
  end

  defp description() do
    "ActiveEx is a sync replacement that uses native file-system OS async listeners to automatic compile and to reload after saving all *.ex and *.erl files of a project. It acts as a FS subscriber under supervision.
    NOTE: On Linux you need to install inotify-tools."
  end

  defp deps do
    [
      {:fs, "~> 4.10.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end

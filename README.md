# ActiveEx

ActiveEx is a sync replacement that uses native file-system OS async listeners to automatic compile and to reload after saving all *.ex and *.erl files of a project. It acts as a FS subscriber under supervision. NOTE: On Linux you need to install inotify-tools.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `active_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:active_ex, "~> 1.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/active_ex](https://hexdocs.pm/active_ex).


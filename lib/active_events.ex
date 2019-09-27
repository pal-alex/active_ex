defmodule ActiveEx.Events do
  @moduledoc """
  Documentation for ActiveEx.Events
  """

  @doc """
  Subcribe on :fs events.

  ## Examples

      iex> ActiveEx.hello()
      :world

  """

  use GenServer

    def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end


    ## Callbacks

    @impl true
    def init(_stack) do
      IO.puts("fs subscribe elixir")
      {:ok, pid} = :fs.start_link(:active_ex)
      :fs.subscribe(:active_ex)
      {:ok, pid}
    end

    @impl true
    def handle_call(event, _from, state) do
      inspect(event, label: "active call event:")
      {:reply, :ok, state}
    end

    @impl true
    def handle_cast(event, state) do
      inspect(event, label: "active cast event:")
      {:noreply, state}
    end

    def handle_request(event, state) do
      inspect(event, label: "active request event:")
      {:noreply, state}
    end

    @impl true
    def handle_info({_Pid, {:fs, :file_event}, {path, _flags}}, state) do
      reload(path)

      {:noreply, state}
    end

    def handle_info(event, state) do
      IO.inspect(event, label: "active unknown info")

      {:noreply, state}
    end

    def reload(path) do
      dirs = Path.split(path)
      except = [".elixir_ls", "build", "_build", "ebin", "test", ".git"]
      is_filtered = Enum.any?(except, fn p ->
                                          Enum.member?(dirs, p)
                                       end)

      case is_filtered do
        true -> #IO.inspect(path, label: "active filtered")
                :skip
        false -> case Path.extname(path) do
                  ".erl" -> #IO.inspect(path, label: "active erlang")
                            m = get_module_name(dirs)
                            IO.puts("Recompiling erlang module #{m}")
                            IEx.Helpers.r(m)
                   ".ex" -> #IO.inspect(path, label: "active elixir")
                            m = get_module_name(dirs)
                            IO.puts("Recompiling all elixir modules (active get: #{path})")
                            IEx.Helpers.recompile(force: true)
                            # IEx.Helpers.r(m)
                  ".exs" -> IO.inspect(path, label: "active elixir script")
                  ".hrl" -> IO.inspect(path, label: "active records")
                       _ -> :skip
                            #IO.inspect(path, label: "active trash files")
                end

      end

    end
    def get_module_name(dirs) do
      name = Enum.reduce(dirs, false, fn x, acc -> case acc do
                                              true -> x
                                              false -> case x == "deps" do
                                                        true -> true
                                                        false -> false
                                                      end
                                              _ -> acc
                                            end
                                          end)
      String.to_atom(name)

    end
  end

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
    def init(stack) do
      # IO.puts("fs subscribe elixir")
      {:ok, _pid} = :fs.start_link(:active_ex)
      :fs.subscribe(:active_ex)
      {:ok, stack}
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
    def handle_info({_Pid, {:fs, :file_event}, {path, flags}}, state) do
      reload(path, flags)
      {:noreply, state}
    end

    def handle_info(_event, state) do
      # IO.inspect(event, label: "active unknown info")

      {:noreply, state}
    end

    # @impl true
    # def terminate(reason, state) do
    #   {reason, state}
    # end

    def reload(path, flags) do
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
                            case m do
                              [] -> IO.puts("Couldn't find deps-app name for the erlang path = #{path}")
                              _ -> try do
                                      result = :os.cmd(String.to_charlist("mix deps.compile #{m}"))
                                      case result do
                                        [] -> IEx.Helpers.l(m)
                                              IO.puts("Recompiling erlang module #{m}")
                                        _ -> IO.inspect(result, label: "Recompiling error")
                                      end

                                   rescue
                                      _ -> inspect(__STACKTRACE__)
                                   end
                            end

                            # IO.inspect(flags, label: "path flags")

                   ".ex" -> #IO.inspect(path, label: "active elixir")

                            IO.puts("Recompiling elixir module (active receive: #{path})")
                            try do
                                case IEx.Helpers.c(to_string(path), :in_memory) do
                                  [] -> :ignore
                                  [mod|_] -> IEx.Helpers.r(mod)
                                end
                            rescue
                                _ -> inspect(__STACKTRACE__)
                            end
                            # IEx.Helpers.recompile(force: true)

                            # IEx.Helpers.r(m)
                  ".exs" -> IO.inspect(path, label: "active elixir script")
                  ".hrl" -> IO.inspect(path, label: "active records")
                       _ -> :skip
                            #IO.inspect(path, label: "active trash files")
                end

      end

    end

    def test() do
      IO.puts("test 4!")
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

      case is_boolean(name) do
        true -> []
        false -> String.to_atom(name)
      end


    end
  end

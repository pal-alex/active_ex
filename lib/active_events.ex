defmodule ActiveEx.Events do
  @moduledoc """
  Documentation for ActiveEx.Events
  """

  @doc """
  Subcribe on :fs events.
  ReCompiling all *.ex and *.erl files

  """

  use GenServer

    def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end


    ## Callbacks

    @impl true
    def init(stack) do
      Process.flag(:trap_exit, true)
      IO.puts("fs subscribe active_ex")
      {:ok, _pid} = :fs.start_link(:active_ex)
      :fs.subscribe(:active_ex)
      {:ok, stack}
    end

    @impl true
    def handle_call(event, _from, state) do
      inspect(event, label: "active_ex: call event:")
      {:reply, :ok, state}
    end


    @impl true
    def handle_cast(event, state) do
      inspect(event, label: "active_ex: cast event:")
      # spawn (fn -> ActiveEx.start self, {} end)
      {:noreply, state}
    end

    def handle_request(event, state) do
      inspect(event, label: "active_ex: request event:")
      {:noreply, state}
    end

    @impl true
    def handle_info({_Pid, {:fs, :file_event}, {path, flags}}, state) do
      # IO.inspect(state, label: "state before file_event #{path}")
      stateAfter = reload(path, flags, state)
      {:noreply, stateAfter}
    end

    def handle_info({_port, {:exit_status, _status}}, state) do
      acc = Keyword.get(state, :acc, [])
      messages = :erlang.iolist_to_binary(:lists.reverse(acc))
      IO.puts(messages)
      mod = Keyword.fetch!(state, :mod)
      IEx.Helpers.l(mod)
      stateAfter = []
      {:noreply, stateAfter}
    end

    def handle_info({_port, {:data, {type, line}}}, state) when type == :eol or type == :noeol do
        # IO.inspect(state, label: "state before line")
        acc = Keyword.get(state, :acc, [])
        stateAfter = Keyword.put(state, :acc, [line|acc])
        {:noreply, stateAfter}
    end

    def handle_info({_port, {:data, data}}, state) do
      # IO.inspect(state, label: "state before :data")
      acc = Keyword.get(state, :acc, [])
      stateAfter = Keyword.put(state, :acc, [data|acc])
      {:noreply, stateAfter}
    end
    def handle_info({_port, :eof}, state), do: {:noreply, state}

    def handle_info(:run, state) do
      # IO.inspect(state, label: "state before run")
      mod = Keyword.fetch!(state, :mod)
      case mod do
        [] -> :skip
        _ -> run(String.to_charlist("mix deps.compile #{mod}"))
      end

      {:noreply, state}
    end

    def handle_info(event, state) do
      IO.inspect(event, label: "active_ex: unknown info")
      {:noreply, state}
    end


    @impl true
    def terminate(reason, state) do
      IO.inspect(reason, label: "active_ex: terminating")
      {reason, state}
    end

    def reload(path, _flags, state) do
      dirs = Path.split(path)
      except = [".elixir_ls", "build", "_build", "ebin", "test", ".git"]
      is_filtered = Enum.any?(except, fn p ->
                                          Enum.member?(dirs, p)
                                       end)

      stateAfter = case is_filtered do
                      true -> #IO.inspect(path, label: "active filtered")
                              state
                      false -> path_before = Keyword.get(state, :path, [])
                              ext = Path.extname(path)
                              stateAfter1 = case {path, ext} do
                                              {^path_before, _} -> state
                                              {_, ext} when ext == ".erl" or ext == ".hrl" ->
                                                            state0 = Keyword.put(state, :path, path)
                                                            mod = get_module_name(dirs)

                                                            stateAfter0 = case mod do
                                                                              [] -> IO.puts("active_ex: Recompiling erlang modules (received: #{path})")
                                                                                    try do
                                                                                        compile_load(path, false)
                                                                                    rescue
                                                                                        _ -> inspect(__STACKTRACE__)
                                                                                    end
                                                                                    state0
                                                                              _ -> IO.puts("active_ex: Recompiling deps/#{mod} erlang project (received: #{path})")
                                                                                    state1 = Keyword.put(state0, :mod, mod)
                                                                                    try do
                                                                                      handle_info(:run, state1)
                                                                                    rescue
                                                                                      _ -> inspect(__STACKTRACE__)
                                                                                    end
                                                                                    state1
                                                                            end
                                                            stateAfter0
                                                            # IO.inspect(flags, label: "path flags")

                                              {_, ".ex"} -> state0 = Keyword.put(state, :path, path)
                                                            IO.puts("active_ex: Recompiling elixir module (received: #{path})")
                                                            try do
                                                                compile_load(path, true)
                                                            rescue
                                                                _ -> inspect(__STACKTRACE__)
                                                            end
                                                            []

                                              {_, ".exs"} -> IO.inspect(path, label: "active_ex: Changed elixir script (do nothing)")
                                                            state
                                              {_, _} -> state
                                                      #IO.inspect(path, label: "active_ex trash files")
                                          end
                                # IO.inspect(stateAfter1, label: "(RELOAD) stateAfter1")
                                stateAfter1

            end
      stateAfter
    end

    def compile_load(path, recompile) do
      case IEx.Helpers.c(to_string(path), :in_memory) do
        [] -> IO.puts("active_ex: Couldn't compile #{path}")
              :ignore
        modules -> Enum.each(modules, fn(mod) -> case recompile do
                                                    true -> IEx.Helpers.r(mod)
                                                    false -> IEx.Helpers.l(mod)
                                                 end
                                      end)
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


    # sh functions
    def reduce({_, chunk}, acc), do: [chunk|acc]
    def reduce([], acc), do: acc
    def reduce(data, acc), do: [data|acc]

    def run(args) do
      _port = :erlang.open_port({:spawn_executable, :os.find_executable('sh')},
                        [:stream, :in, :out, :eof, :use_stdio, :stderr_to_stdout, :binary, :exit_status,
                          {:args, ["-c", args]}, {:cd, :erlang.element(2, :file.get_cwd())}, {:env, []}])

      # {:done, _status, info} = sh(port)
      # info
    end

    def sh(port), do: sh(port, &__MODULE__.reduce/2, [])
    def sh(port, fun, acc) do
          receive do
            # {_Pid, {:fs, :file_event}, {^path, _}} -> sh(port, fun, fun.([], acc))
            {_Pid, {:fs, :file_event}, _} = data -> handle_info(data, [])
                                            sh(port, fun, fun.([], acc))
            # {^port, :eof} -> sh(port, fun, fun.([], acc))
            {^port, {:exit_status, status}} -> {:done, status, :erlang.iolist_to_binary(:lists.reverse(acc))}

              {^port, {:data, {:eol, line}}} -> sh(port, fun, fun.({:eol, line}, acc))
            {^port, {:data, {:noeol, line}}} -> sh(port, fun, fun.({:noeol, line}, acc))
                      {^port, {:data, data}} -> sh(port, fun, fun.(data, acc))
                       data -> #IO.inspect(data, label: "sh loop ignore data")
                              handle_info(data, [])
                              sh(port, fun, fun.([], acc)) #{:exit, data, :erlang.iolist_to_binary(:lists.reverse(acc))}

          end
    end

  end

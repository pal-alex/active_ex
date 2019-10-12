defmodule ActiveEx do
  use Supervisor

  def start(), do: start([],[])
  def start(_,_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {ActiveEx.Events, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end




end

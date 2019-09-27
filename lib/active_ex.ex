defmodule ActiveEx.Supervisor do
  @moduledoc """
  Documentation for ActiveEx.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ActiveEx.hello()
      :world

  """
  use Supervisor

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

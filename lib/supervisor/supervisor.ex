defmodule Raft.Supervisor do
  use Supervisor
  require Logger

  def startSupervisor(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(init_arg) do
    children = [
      %{
        id: Raft.Comms,
        start: {Raft.Comms, :startServer,[]}
      },
      %{
        id: Raft.MessageProcessing.Main,
        start: {Raft.MessageProcessing.Main, :start_link, [init_arg]}
      },
      %{
        id: Raft.Timer,
        start: {Raft.Timer, :start_link, []}
      }

    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def which_children do
    children =
      Supervisor.which_children(__MODULE__)
      |> Enum.map(fn {name, pid, _, _} -> {name, pid} end)

    {:ok, children}
  end

end

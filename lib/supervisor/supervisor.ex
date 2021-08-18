defmodule Raft.Supervisor do
  @moduledoc """
  Module to hold the main Raft Supervisor for all the GenServer children. The GenServers used by this implementation of the Raft protocol are:
  1) Raft.Comms - Acts as the communication layer between the nodes in the cluster.
  2) Raft.MessageProcessing - Acts as the main Message Processing module for all the RCPs and messages received from the nodes in the cluster.
  3) Raft.ElectionTimer - Acts as the Election timer for the Raft protocol.
  4) Raft.HeartbeatTimer - Acts as the Heartbeat timer for the Raft protocol used by the leader node.
  5) Raft.StateToDisk - Acts as the stable storage layer used by the Raft ptotocol to store the state to the non-volatile storage


  """
  use Supervisor
  require Logger

  def startSupervisor(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(init_arg) do
    children = [
      %{
        id: Raft.Comms,
        start: {Raft.Comms, :startServer, []}
      },
      %{
        id: Raft.MessageProcessing.Main,
        start: {Raft.MessageProcessing.Main, :start_link, [init_arg]}
      },
      %{
        id: Raft.ElectionTimer,
        start: {Raft.ElectionTimer, :start_link, []}
      },
      %{
        id: Raft.HeartbeatTimer,
        start: {Raft.HeartbeatTimer, :start_link, []}
      },
      %{
        id: Raft.StateToDisk,
        start: {Raft.StateToDisk, :start_link, []}
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

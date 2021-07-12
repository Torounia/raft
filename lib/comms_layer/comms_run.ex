defmodule Raft.Comms do
  use GenServer
  require Logger
  alias Raft.ClusterConfig, as: ClusterConfig
  # client API

  def startServer() do
    GenServer.start_link(__MODULE__, %{}, name: :server)
  end

  def broadcast(nodes, source, msg) do
    Logger.debug("[#{Node.self()}] Broadcasting #{msg} to all nodes")
    GenServer.abcast(nodes, :server, {:broadcast, source, msg})
  end

  def send_msg(source, dest, msg) do
    Logger.debug("[#{Node.self()}] Sending #{inspect(msg)} to #{inspect(dest)}")
    # TODO use PID for dest instead of name  e.g :global.whereis_name(:peer2@localhost_comms)
    GenServer.cast(dest, {:sendMsg, source, msg})
  end

  # callbacks
  def init(state) do
    ClusterConfig.init()
    {:ok, state}
  end

  def handle_cast({:broadcast, source, msg}, state) do
    Logger.debug("[#{Node.self()}] Received broadcast #{inspect(msg)} from #{inspect(source)}")
    {:noreply, state}
  end

  def handle_cast({:sendMsg, source, msg}, state) do
    Logger.debug("[#{Node.self()}] Received msg #{inspect(msg)} from #{inspect(source)}")
    {:noreply, state}
    # :global.register_name(:peer2@locahost, Process.whereis(:peer2@localhost))
  end
end

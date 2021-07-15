defmodule Raft.Comms do
  use GenServer
  require Logger
  alias Raft.ClusterConfig, as: ClusterConfig
  # client API

  def startServer() do
    Logger.debug("Starting Comms GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def broadcast(nodes, source, msg) do
    Logger.debug("[Broadcasting #{inspect(msg)} to all nodes")

    GenServer.abcast(nodes, :server, {:broadcast, source, msg})
  end

  def send_msg(source, dest, msg) do
    Logger.debug("#{:global.whereis_name(dest)}")

    case :global.whereis_name(dest) do
      :undefined ->
        Logger.debug("Cannot find #{inspect(dest)} in the cluster")

      pid ->
        Logger.debug("Sending #{inspect(msg)} to #{inspect(dest)}")

        GenServer.cast(pid, {:sendMsg, source, msg})
    end
  end

  # callbacks
  def init(state) do
    ClusterConfig.init()
    {:ok, state}
  end

  def handle_cast({:broadcast, source, msg}, state) do
    Logger.debug("Received broadcast #{inspect(msg)} from #{inspect(source)}")

    {:noreply, state}
  end

  def handle_cast({:sendMsg, source, msg}, state) do
    Logger.debug("Received msg #{inspect(msg)} from #{inspect(source)}")

    {:noreply, state}
    # :global.register_name(:peer2@locahost, Process.whereis(:peer2@localhost))
  end
end

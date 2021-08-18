defmodule Raft.Client do
  @moduledoc """
  Module to hold client role code for the Raft protocol.
  For testing purposes the client will be a seperate node with its own Genserver instance in order to communicate with the Raft protocol

  client commands:
    add_to_log (receive confirmation)
    see current status
    retrieve log
    retrive last log
  """
  use GenServer
  require Logger
  alias Raft.ClusterConfig, as: ClusterConfig

  def startClient() do
    Logger.debug("Starting Client GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def send_msg(source, dest, msg) do
    case :global.whereis_name(dest) do
      :undefined ->
        Logger.debug("Cannot find #{inspect(dest)} in the cluster")

      pid ->
        Logger.debug(
          "Sending #{inspect(msg)} to #{inspect(dest)} @ #{inspect(:global.whereis_name(dest))}"
        )

        GenServer.cast(pid, {:sendMsg, source, msg})
    end
  end

  def init(state) do
    ClusterConfig.init()
    {:ok, state}
  end

  def handle_cast({:sendMsg, source, msg}, state) do
    Logger.info("Received msg #{inspect(msg)} from #{inspect(source)}.")

    # MP.received_msg(msg)
    {:noreply, state}
  end
end

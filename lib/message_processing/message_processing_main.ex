defmodule Raft.MessageProcessing do
  use GenServer
  require Logger

  # client API

  def startServer(state) do
    GenServer.start_link(__MODULE__, state, name: :server)
  end

  def append(nodes, var, val) do
    GenServer.abcast(nodes, :server, {:append, var, val})
  end

  def showState do
    GenServer.call(:server, :showState)
  end

  # callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:append, var, val}, state) do
    Logger.debug("I am #{inspect(Node.self())}, received broadcast :append #{var}, #{val} ")
    {:noreply, Map.replace(state, var, val)}
  end

  def handle_call(:showStat, _from, state) do
    {:reply, state, state}
  end
end

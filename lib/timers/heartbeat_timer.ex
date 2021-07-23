defmodule Raft.HeartbeatTimer do
  use GenServer
  require Logger
  alias Raft.MessageProcessing.Main, as: MP

  def start_link() do
    Logger.debug("Starting HeartbeatTimer GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start() do
    GenServer.call(__MODULE__, :start_heartbeat_timer)
  end

  def reset() do
    GenServer.call(__MODULE__, :reset_heartbeat_timer)
  end

  def init(%{}) do
    {:ok, %{}}
  end

  def handle_call(:start_heartbeat_timer, _from, %{}) do
    timeout = %Raft.Configurations{}.heartbeat_timeout
    timer = Process.send_after(__MODULE__, :heartbeat, timeout)
    Logger.debug("Heartbeat timer start")
    {:reply, :ok, %{heartbeat_timer: timer}}
  end

  def handle_call(:reset_heartbeat_timer, _from, %{heartbeat_timer: timer}) do
    :timer.cancel(timer)
    timeout = %Raft.Configurations{}.heartbeat_timeout
    timer = Process.send_after(__MODULE__, :heartbeat, timeout)
    Logger.debug("Reseting Heartbeat timer")
    {:reply, :ok, %{heartbeat_timer: timer}}
  end

  def handle_info(:heartbeat, %{heartbeat_timer: timer}) do
    Logger.debug("Heartbeat timeout")
    MP.heartbeat_timer_timeout()
    :timer.cancel(timer)
    {:noreply, %{heartbeat_timer: nil}}
  end
end

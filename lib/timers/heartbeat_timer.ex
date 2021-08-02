defmodule Raft.HeartbeatTimer do
  use GenServer
  require Logger
  alias Raft.MessageProcessing.Main, as: MP

  def start_link() do
    Logger.debug("Starting HeartbeatTimer GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start() do
    GenServer.cast(__MODULE__, :start_heartbeat_timer)
  end

  def reset() do
    GenServer.cast(__MODULE__, :reset_heartbeat_timer)
  end

  def init(%{}) do
    {:ok, %{heartbeat_timer: nil}}
  end

  def handle_cast(:start_heartbeat_timer, %{heartbeat_timer: timer}) do
    new_timer = if timer == nil do
      Logger.debug("No heartbeat timer to reset. Starting new heartbeat timer")
      timeout = %Raft.Configurations{}.heartbeat_timeout
      new_timer = Process.send_after(__MODULE__, :heartbeat, timeout)
      Logger.debug("New heartbeat timer #{inspect(new_timer)}")
      new_timer
    else
      Logger.debug("Cancelling election timer #{inspect(timer)}")
      Process.cancel_timer(timer)
      timeout = %Raft.Configurations{}.heartbeat_timeout
      new_timer = Process.send_after(__MODULE__, :heartbeat, timeout)
      Logger.debug("New timer heartbeat timer #{inspect(new_timer)}")
      new_timer
    end

    {:noreply, %{heartbeat_timer: new_timer}}
  end

  # def handle_cast(:reset_heartbeat_timer, %{heartbeat_timer: timer}) do
  #   Logger.debug("Reseting Heartbeat timer: #{inspect(timer)}")
  #   Process.cancel_timer(timer)
  #   timeout = %Raft.Configurations{}.heartbeat_timeout
  #   new_timer = Process.send_after(__MODULE__, :heartbeat, timeout)
  #   Logger.debug("Starting Heartbeat timer: #{inspect(new_timer)}")
  #   {:noreply, %{heartbeat_timer: new_timer}}
  # end

  def handle_info(:heartbeat, %{heartbeat_timer: timer}) do
    Logger.debug("Heartbeat timeout for timer: #{inspect(timer)}")
    Process.cancel_timer(timer)
    MP.heartbeat_timer_timeout()
    {:noreply, %{heartbeat_timer: nil}}
  end

end

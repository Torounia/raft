defmodule Raft.ElectionTimer do
  use GenServer
  require Logger
  alias Raft.MessageProcessing.Main, as: MP
  alias Raft.RandTimer

  def start_link() do
    Logger.debug("Starting ElectionTimer GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start() do
    GenServer.call(__MODULE__, :start_election_timer)
  end

  def reset_timer() do
    GenServer.call(__MODULE__, :reset_timer)
  end

  def cancel() do
    GenServer.call(__MODULE__, :cancel_election_timer)
  end

  def init(%{}) do
    {:ok, %{election_timer: nil, timerID: 0}}
  end

  # def handle_call(:start_election_timer, _from, %{election_timer: nil, timerID: timer_ID}) do
  #   timeout = RandTimer.rand_election_timeout()
  #   timer = Process.send_after(__MODULE__, :work, timeout)
  #   new_timer_ID = timer_ID + 1
  #   Logger.debug("Starting election timer for #{inspect(timeout)} ms, ID: #{inspect(new_timer_ID)}")
  #   {:reply, :ok, %{election_timer: timer, timerID: new_timer_ID}}
  # end

  def handle_call(:start_election_timer, _from, %{election_timer: timer, timerID: timer_ID}) do
    timeout = RandTimer.rand_election_timeout()
    timer = Process.send_after(__MODULE__, :work, timeout)
    new_timer_ID = timer_ID + 1
    Logger.debug("Starting election timer for #{inspect(timeout)} ms, ID: #{inspect(timer_ID)}")
    {:reply, :ok, %{election_timer: timer, timerID: new_timer_ID}}
  end

  def handle_call(:reset_timer, _from, %{election_timer: timer, timerID: timer_ID}) do
    :timer.cancel(timer)
    timeout = RandTimer.rand_election_timeout()
    timer = Process.send_after(__MODULE__, :work, timeout)
    new_timer_ID = timer_ID + 1
    Logger.debug("Reseting election timer for #{inspect(timeout)} ms, ID: #{inspect(timer_ID)}")
    {:reply, :ok, %{election_timer: timer, timerID: new_timer_ID}}
  end

  # def handle_call(:reset_timer, _from, %{}) do
  #   Logger.debug("Reset timer without state. Invastigate")
  #   timeout = RandTimer.rand_election_timeout()
  #   timer = Process.send_after(__MODULE__, :work, timeout)
  #   {:reply, :ok, %{election_timer: timer}}
  # end

  def handle_call(:cancel_election_timer, _from, %{election_timer: timer, timerID: timer_ID}) do
    :timer.cancel(timer)
    Logger.debug("Cancelling timer #{inspect(timer_ID)}")
    {:reply, :ok, %{election_timer: nil, timerID: timer_ID}}
  end

  def handle_info(:work, %{election_timer: timer, timerID: timer_ID}) do
    :timer.cancel(timer)
    Logger.debug("Election timeout")
    MP.election_timer_timeout()
    {:noreply, %{election_timer: nil, timerID: timer_ID}}
  end
end

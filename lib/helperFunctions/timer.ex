defmodule Raft.Timer do
  use GenServer
  require Logger
  alias Raft.MessageProcessing.Main, as: MP
  alias Raft.RandTimer

  def start_link() do
    Logger.debug("Starting Timer GenServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_election_timer() do
    GenServer.call(__MODULE__, :start_election_timer)
  end

  def reset_timer() do
    GenServer.call(__MODULE__, :reset_timer)
  end

  def cancel_election_timer() do
    GenServer.call(__MODULE__, :cancel_election_timer)
  end

  def init(%{}) do
    {:ok, %{}}
  end

  def handle_call(:start_election_timer, _from, %{}) do
    timeout = RandTimer.rand_election_timeout()
    timer = Process.send_after(__MODULE__, :work, timeout)
    Logger.debug("Timer set for #{inspect(timeout)} ms")
    {:reply, :ok, %{election_timer: timer}}
  end

  def handle_call(:reset_timer, _from, %{election_timer: timer}) do
    :timer.cancel(timer)
    timeout = RandTimer.rand_election_timeout()
    timer = Process.send_after(__MODULE__, :work, timeout)
    {:reply, :ok, %{election_timer: timer}}
  end

  def handle_call(:cancel_election_timer, _from, %{election_timer: timer}) do
    :timer.cancel(timer)
    {:reply, :ok, %{}}
  end

  def handle_info(:work, %{election_timer: timer}) do
    Logger.debug("timeout. calling above")
    MP.heartbeat_timer_timeout()
    :timer.cancel(timer)
    {:noreply, %{}}
  end

  # unhandled messages don't error
  def handle_info(_, state) do
    {:ok, state}
  end
end

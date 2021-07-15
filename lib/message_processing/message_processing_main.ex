defmodule Raft.MessageProcessing.Main do
  use GenServer
  require Logger

  alias Raft.MessageProcessing.Types, as: MP_types

  # client API

  def start_link(state) do
    Logger.debug("Starting MessageProcessing GenServer")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def heartbeat_timer_timeout do
    GenServer.call(__MODULE__, :heartbeat_timer_timeout)
  end

  def first_time_run do
    GenServer.call(__MODULE__, :first_time_run)
  end

  # callbacks
  def init(state) do
    GenServer.call(__MODULE__, :first_time_run)
    {:ok, state}
  end

  def handle_call(:heartbeat_timer_timeout, _from, state) do
    new_state = MP_types.canditate(state)
    {:reply, :starting_election, new_state}
  end

  # TODOspin a new process to use this function
  def handle_info(:first_time_run, state) do
    MP_types.first_time_run(state)
    {:reply, :ok, state}
  end
end

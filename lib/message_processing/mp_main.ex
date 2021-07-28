defmodule Raft.MessageProcessing.Main do
  use GenServer
  require Logger

  alias Raft.MessageProcessing.Types, as: MP_types

  # client API

  def start_link(state) do
    Logger.debug("Starting MessageProcessing GenServer")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def election_timer_timeout do
    GenServer.cast(__MODULE__, :election_timer_timeout)
  end

  def heartbeat_timer_timeout do
    GenServer.cast(__MODULE__, :heartbeat_timer_timeout)
  end

  def first_time_run do
    send(__MODULE__, :first_time_run)
  end

  def received_msg(msg) do
    GenServer.cast(__MODULE__, {:received_msg, msg})
  end

  def new_entry(msg) do
    GenServer.cast(__MODULE__, {:new_entry, msg})
  end

  # callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast(:election_timer_timeout, state) do
    new_state = MP_types.canditate(state)
    {:noreply, new_state}
  end

  def handle_cast(:heartbeat_timer_timeout, state) do
    MP_types.heartbeat_timout(state)
    {:noreply, state}
  end

  def handle_cast({:received_msg, msg}, state) do
    new_state =
      case msg do
        {:voteRequest, payload} ->
          Logger.debug("Received voteRequest. Sending to MessageProcessing")
          MP_types.vote_request(payload, state)

        {:voteResponse, payload} ->
          Logger.debug("Received voteResponse. Sending to MessageProcessing")
          MP_types.vote_response(payload, state)

        {:logNewEntry, payload} ->
          Logger.debug("Received logNewEntry. Sending to MessageProcessing")
          MP_types.new_entry_to_log(payload, state)

        {:logRequest, payload} ->
          Logger.debug("Received logRequest. Sending to MessageProcessing")
          MP_types.log_request(payload, state)

        {:logResponse, payload} ->
          Logger.debug("Received logResponse. Sending to MessageProcessing")
          MP_types.log_response(payload, state)
      end

    # Logger.debug("New state = #{inspect(new_state)}")
    {:noreply, new_state}
  end

  def handle_cast({:new_entry, msg}, state) do
    Logger.debug("Received new log entry. Sending to MessageProcessing")
    new_state = MP_types.new_entry_to_log(msg, state)

    {:noreply, new_state}
  end

  def handle_info(:first_time_run, state) do
    MP_types.first_time_run(state)
    {:noreply, state}
  end
end

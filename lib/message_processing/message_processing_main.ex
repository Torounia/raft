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
    send(__MODULE__, :first_time_run)
  end

  def received_msg(msg) do
    GenServer.call(__MODULE__, {:received_msg, msg})
  end

  # callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call(:heartbeat_timer_timeout, from, state) do
    GenServer.reply(from, :ok)
    new_state = MP_types.canditate(state)
    {:reply, :ok, new_state}
  end

  def handle_call({:received_msg, msg}, from, state) do
    GenServer.reply(from, :ok)

    new_state =
      case msg do
        {:VoteRequest, payload} ->
          Logger.debug("Received voteRequest. Sending to MessageProcessing")
          MP_types.rec_vote_request(payload, state)

        {:VoteResponse, payload} ->
          Logger.debug("Received voteResponse. Sending to MessageProcessing")
          MP_types.rec_vote_response(payload, state)
      end

    # Logger.debug("New state = #{inspect(new_state)}")
    {:reply, :ok, new_state}
  end

  def handle_info(:first_time_run, state) do
    MP_types.first_time_run(state)
    {:noreply, state}
  end
end

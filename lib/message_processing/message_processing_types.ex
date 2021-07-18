defmodule Raft.MessageProcessing.Types do
  require Logger
  alias Raft.Timer, as: Timer
  alias Raft.MessageProcessing.Helpers, as: Helpers
  alias Raft.Comms, as: Comms
  alias Raft.Configurations

  def first_time_run(state) do
    Logger.debug("First time run state #{inspect(state)}")

    if state.current_role == :follower do
      Logger.debug("Starting heartbeat timer")
      Timer.start_election_timer()
    end
  end

  def canditate(state) do
    Logger.debug("Times is up. Starting election on node #{inspect(Node.self())}")

    state = %{
      state
      | current_term: state.current_term + 1,
        current_role: :candidate,
        voted_for: Node.self(),
        votes_received: [Node.self() | state.votes_received] |> Enum.reverse()
    }

    last_term = Helpers.log_last_term(state)

    broadcast_payload =
      {:VoteRequest, {Node.self(), state.current_term, Enum.count(state.log), last_term}}

    broadcast =
      Comms.broadcast(
        %Raft.Configurations{}.peers,
        Node.self(),
        broadcast_payload
      )

    # TODO, Nodes should be obtained differently, From init config?

    if broadcast do
      Logger.debug("Starting election timer")
      Timer.reset_timer()
    else
      Logger.error("Msg #{inspect(broadcast_payload)} has not been broadcasted")
    end

    state
  end

  def rec_vote_request({c_Id, c_term, c_log_length, c_log_term}, state) do
    my_log_term = Helpers.log_last_term(state)

    log_ok =
      if c_log_term > my_log_term or
           (c_log_term == my_log_term and c_log_length >= Enum.count(state.log)) do
        true
      else
        false
      end

    term_ok =
      if c_term > state.current_term or
           (c_term == state.current_term and (state.voted_for == c_Id or state.voted_for == nil)) do
        true
      else
        false
      end

    state =
      if log_ok and term_ok do
        Comms.send_msg(
          Node.self(),
          c_Id,
          {:voteResponse, {Node.self(), state.current_term, true}}
        )

        %{
          state
          | current_term: c_term,
            current_role: :follower,
            voted_for: c_Id
        }
      else
        Comms.send_msg(
          Node.self(),
          c_Id,
          {:voteResponse, {Node.self(), state.current_term, false}}
        )

        state
      end
  end

  def rec_vote_reponse({voter_id, term, granded}, state) do
    state =
      if state.current_role == :candidate and term == state.current_term and granded do
        %{state | votes_received: [voter_id | state.votes_received] |> Enum.reverse()}

        if Helpers.check_quorum(state) do
          %{state | current_role: :leader, current_leader: Node.self()}
          Timer.cancel_election_timer()
        end
      end
  end
end

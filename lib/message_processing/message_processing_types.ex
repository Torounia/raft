defmodule Raft.MessageProcessing.Types do
  require Logger
  alias Raft.Timer, as: Timer
  alias Raft.MessageProcessing.Helpers, as: Helpers
  alias Raft.Comms, as: Comms
  alias Raft.Configurations
  alias Raft.LogEnt

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

    Helpers.store_state_to_disk(state)
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

  def vote_request({c_Id, c_term, c_log_length, c_log_term}, state) do
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

        state = %{
          state
          | current_term: c_term,
            current_role: :follower,
            voted_for: c_Id
        }

        Helpers.store_state_to_disk(state)
        state
      else
        Comms.send_msg(
          Node.self(),
          c_Id,
          {:voteResponse, {Node.self(), state.current_term, false}}
        )

        state
      end

    state
  end

  def vote_response({voter_id, term, granded}, state) do
    state =
      if term > state.current_term do
        Logger.debug(
          "Received higher term #{inspect(term)} from voter #{inspect(voter_id)}. Transitioning to :follower"
        )

        %{
          state
          | current_term: term,
            current_role: :follower,
            voted_for: nil
        }

        ## TODO seperate timers
        # Timer.reset_timer()
      else
        state
      end

    state =
      if state.current_role == :candidate and term == state.current_term and granded do
        Logger.debug(
          "Received a valid response from #{inspect(voter_id)}. term: #{
            inspect(state.current_term)
          }"
        )

        Logger.debug("Adding voter: #{inspect(voter_id)} to votes_received ")

        state = %{
          state
          | votes_received: [voter_id | state.votes_received] |> Enum.uniq() |> Enum.reverse()
        }

        state =
          if Helpers.check_quorum(state) do
            Logger.debug(
              "Got majority of votes required for term: #{inspect(state.current_term)}. Transitioning to :leader state."
            )

            Helpers.init_leader_state(state)
            # TODO what is next? start heartbeat?
          else
            state
          end
      else
        state
      end

    # Timer.cancel_election_timer()
    state
  end

  def new_entry_to_log({entry, from}, state) do
    state =
      if state.current_role == :leader do
        IO.puts("111111111111111")

        state = %{
          state
          | log: [%LogEnt{term: state.current_term, cmd: entry} | state.log] |> Enum.reverse()
        }

        IO.inspect(state)

        state = %{
          state
          | acked_length: Map.put(state.acked_length, Node.self(), Enum.count(state.log))
        }

        IO.inspect(state)
        Helpers.store_state_to_disk(state)
        Helpers.replicate_log(state)
        state
      else
        state
      end

    # if state.current_role == :leader do
    #   Helpers.store_state_to_disk(state)
    #   Helpers.replicate_log(state)
    # end

    if state.current_role == :follower or state.current_role == :candidate do
      Logger.debug(
        "Received new log entry request from #{inspect(from)}. Current role #{
          inspect(state.current_role)
        } Sending to leader"
      )

      Comms.send_msg(
        Node.self(),
        ## TODO, what if there is no leader to sent to? Also, do we need to send back a confirmation after commit?
        state.current_leader,
        {:logNewEntry, {entry, Node.self()}}
      )
    end

    state
  end

  def replicate_log(state) do
    index = nil
  end
end

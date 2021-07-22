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
      Logger.debug("Starting follower election timeout timer")
      Timer.start_election_timer()
    end
  end

  def canditate(state) do
    Logger.debug("Times is up. Starting election on node #{inspect(Node.self())}")
    Logger.debug("Starting election timer")
    Timer.reset_timer()

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

    Comms.broadcast(
      %Raft.Configurations{}.peers,
      Node.self(),
      broadcast_payload
    )

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
        Timer.reset_timer()
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
    Logger.debug("Entry - vote_response. state: #{inspect(state)}")

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

            state = Helpers.init_leader_state(state)
            Timer.cancel_election_timer()
            Helpers.replicate_log_all(state)
            # TODO what is next? start heartbeat?
            state
          else
            state
          end

        state
      else
        state
      end

    Logger.debug("Exit - vote_response. state: #{inspect(state)}")
    state
  end

  def new_entry_to_log({entry, from}, state) do
    Logger.debug("Entry - new_entry_to_log. state: #{inspect(state)}")

    state =
      if state.current_role == :leader do
        state = %{
          state
          | log: [%LogEnt{term: state.current_term, cmd: entry} | state.log] |> Enum.reverse()
        }

        state = %{
          state
          | acked_length: Map.put(state.acked_length, Node.self(), Enum.count(state.log))
        }

        Helpers.store_state_to_disk(state)
        Helpers.replicate_log_all(state)
        state
      else
        state
      end

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

    Logger.debug("Exit - new_entry_to_log. state: #{inspect(state)}")
    state
  end

  def log_request({leader_id, term, log_length, log_term, leader_commit, entries}, state) do
    Logger.debug("Entry - log_request. state: #{inspect(state)}")

    state =
      if term > state.current_term do
        %{
          state
          | current_term: term,
            voted_for: nil,
            current_role: :follower,
            current_leader: leader_id
        }
      else
        state
      end

    state =
      if term == state.current_term and state.current_role == :candidate do
        %{
          state
          | current_role: :follower,
            current_leader: leader_id
        }
      else
        state
      end

    log_ok =
      if Enum.count(state.log) >= log_length and
           (log_length == 0 or log_term == Enum.fetch!(state.log, log_length - 1).term) do
        true
      else
        false
      end

    state =
      if term == state.current_term and log_ok do
        state = Helpers.append_entries(log_length, leader_commit, entries, state)
        acked = log_length + Enum.count(entries)

        Raft.Comms.send_msg(
          Node.self(),
          leader_id,
          {:logResponse, {Node.self(), state.current_term, acked, true}}
        )

        Timer.reset_timer()
        state
      else
        Raft.Comms.send_msg(
          Node.self(),
          leader_id,
          {:logResponse, {Node.self(), state.current_term, 0, false}}
        )

        Timer.reset_timer()
        state
      end

    Logger.debug("Exit - log_request. state: #{inspect(state)}")
    state
  end

  def log_response({follower, term, ack, success}, state) do
    state =
      if term == state.current_term and state.current_role == :leader do
        if success == true and ack >= Map.get(state.acked_length, follower) do
          state = %{
            state
            | sent_length: Map.put(state.sent_length, follower, ack),
              acked_length: Map.put(state.acked_length, follower, ack)
          }

          state = Helpers.commit_log_entries(state)
          state
        else
          state =
            if Map.get(state.sent_length, follower) > 0 do
              state = %{
                state
                | sent_length:
                    Map.put(state.sent_length, follower, Map.get(state.sent_length, follower) - 1)
              }

              Helpers.replicate_log_single(follower, state)
              state
            else
              state
            end

          state
        end
      else
        state =
          if term > state.current_term do
            %{
              state
              | current_term: term,
                voted_for: nil,
                current_role: :follower
            }
          else
            state
          end

        state
      end

    state
  end

  def heartbeat_timout(state) do
    Logger.debug("Sending Heartbeat Message")
    Helpers.replicate_log_all(state)
    Timer.reset_heartbeat_timer()
  end
end

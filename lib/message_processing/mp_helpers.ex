defmodule Raft.MessageProcessing.Helpers do
  require Logger

  def log_last_term(state) do
    log_length = Enum.count(state.log)

    last_term =
      if log_length > 0 do
        last_log = Enum.fetch!(state.log, log_length - 1)
        last_log.term
      else
        0
      end

    last_term
  end

  def check_quorum(state) do
    if state.votes_received >= round((state.cluster_size + 1) / 2), do: true, else: false
  end

  def init_leader_state(state) do
    state = %{
      state
      | sent_length:
          Enum.reduce(state.peers, %{}, fn node, acc ->
            Map.put(acc, node, Enum.count(state.log))
          end),
        acked_length:
          Enum.reduce(state.peers, %{}, fn node, acc ->
            Map.put(acc, node, 0)
          end),
        current_role: :leader,
        current_leader: Node.self()
    }

    state
  end

  def store_state_to_disk(state) do
    state_to_save = %{
      current_term: state.current_term,
      voted_for: state.voted_for,
      log: state.log,
      commit_length: state.commit_length
    }

    # case Raft.DETS.store(state_to_save) do
    #   :ok -> Logger.debug("State saved to disk")
    #   {:error, type} -> Logger.debug("Error while saving state to disk: #{inspect(type)}")
    # end
    state
  end

  def replicate_log_all(state) do
    nodes_not_self = Enum.filter(state.peers, fn node -> node != Node.self() end)
    for node <- nodes_not_self, do: replicate_log_single(node, state)
    state
  end

  def replicate_log_single(follower_id, state) do
    index = state.sent_length[follower_id]

    entries =
      if index == Enum.count(state.log) do
        []
      else
        Enum.slice(state.log, index..(Enum.count(state.log) - 1))
      end

    prev_log_term =
      if index > 0 do
        Enum.fetch!(state.log, index - 1).term
      else
        0
      end

    Raft.Comms.send_msg(
      Node.self(),
      follower_id,
      {:logRequest,
       {Node.self(), state.current_term, index, prev_log_term, state.commit_length, entries}}
    )

    state
  end

  def append_entries(log_length, leader_commit, entries, state) do
    state =
      if Enum.count(entries) > 0 and Enum.count(state.log) > log_length do
        if Enum.fetch!(state.log, log_length).term != Enum.fetch!(entries, 0).term do
          %{state | log: Enum.slice(state.log, 0..(log_length - 1))}
        end
      else
        state
      end

    state =
      if log_length + Enum.count(entries) > Enum.count(state.log) do
        log_to_append =
          Enum.slice(state.log, (Enum.count(state.log) - log_length)..Enum.count(entries - 1))

        %{state | log: state.log ++ log_to_append}
      else
        state
      end

    state =
      if leader_commit > state.commit_length do
        msg_to_deliver = Enum.slice(state.log, state.commit_length..(leader_commit - 1))
        for msg <- msg_to_deliver, do: Logger.debug("Message to application #{inspect(msg.cmd)}")
      else
        state
      end

    state
  end

  def commit_log_entries(state) do
    min_acks = round((state.cluster_size + 1) / 2)
    ready = Enum.filter(1..Enum.count(state.log), fn x -> acks(x, state) >= min_acks end)

    state =
      if Enum.count(ready) != 0 and Enum.max(ready) > state.commit_length and
           Enum.fetch!(state.log, Enum.max(ready) - 1).term ==
             state.current_term do
        msg_to_deliver = Enum.slice(state.log, state.commit_length..(Enum.max(ready) - 1))

        for msg <- msg_to_deliver, do: Logger.debug("Message to application #{inspect(msg.cmd)}")
        %{state | commit_length: Enum.max(ready)}
      else
        state
      end

    state
  end

  def acks(len, state) do
    Enum.filter(state.peers, fn x -> Map.get(state.acked_length, x) >= len end) |> Enum.count()
  end
end
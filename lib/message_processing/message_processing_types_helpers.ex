defmodule Raft.MessageProcessing.Helpers do
  require Logger

  def log_last_term(state) do
    log_length = Enum.count(state.log)

    _last_term =
      if log_length > 0 do
        last_log = Enum.at(state.log, log_length - 1)
        last_log.term
      else
        0
      end
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

    replicate_log(state)
    state
  end

  def store_state_to_disk(state) do
    state_to_save = %{
      current_term: state.current_term,
      voted_for: state.voted_for,
      log: state.log,
      commit_length: state.commit_length
    }

    case Raft.DETS.store(state_to_save) do
      :ok -> Logger.debug("State saved to disk")
      {:error, type} -> Logger.debug("Error while saving state to disk: #{inspect(type)}")
    end
  end

  def replicate_log(state) do
    nodes_not_self = Enum.filter(state.peers, fn node -> node != Node.self() end)
    for node <- nodes_not_self, do: replicate_log_function(node, state)
  end

  def replicate_log_function(follower_id, state) do
    index = state.sent_length[follower_id]

    entries =
      if index == Enum.count(state.log) do
        :empty
      else
        Enum.reduce(index..(Enum.count(state.log) - 1), [], fn x, acc -> [x | acc] end)
        |> Enum.reverse()
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
  end
end

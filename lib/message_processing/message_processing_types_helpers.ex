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
    if state.votes_received >= (state.cluster_size + 1) / 2, do: true, else: false
  end
end

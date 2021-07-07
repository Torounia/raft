defmodule Raft do
  def init do
    sState = %{
      # latest term server has seen (initialized to 0 on first boot, increases monotonically)
      currentTerm: 0,

      # candidateId that received vote in current term (or null if none)
      votedFor: nil,

      # log
      log: [
        %{
          index: nil,
          term: nil,
          cmd: nil
        }
      ]
    }

    vState = %{
      # index of highest log entry known to be committed (initialized to 0, increases monotonically)
      commitIndex: 0,

      # index of highest log entry applied to state machine (initialized to 0, increases monotonically)
      lastApplied: 0
    }
  end
end

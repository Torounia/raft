defmodule Raft do
  alias Raft.{
    SStable,
    GetHostIP
  }

  def init do
    # initialise non-volitile state
    sState = initSState()

    # vState = %{
    #   # index of highest log entry known to be committed (initialized to 0, increases monotonically)
    #   commitIndex: 0,

    #   # index of highest log entry applied to state machine (initialized to 0, increases monotonically)
    #   lastApplied: 0
    # }
  end

  def initSState do
    # First look for disk state, if nothing, initialise new sState and return
    sState =
      case SStable.fetch() do
        {:ok, stateFromFile} ->
          stateFromFile

        {:error, :enoent} ->
          %LogEnt{}
          # %{
          #   # latest term server has seen (initialized to 0 on first boot, increases monotonically)
          #   currentTerm: 0,

          #   # candidateId that received vote in current term (or null if none)
          #   votedFor: nil,

          #   # log ToDo: make proper structure
          #   log: [],
          #   commitLength: 0,
          #   lastWriteOperationUTC: nil
          # }
      end
  end
end

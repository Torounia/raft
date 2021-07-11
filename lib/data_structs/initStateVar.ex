defmodule Raft.InitStateVar do
  require Logger

  alias Raft.{
    SStable
  }

  def initVariables() do
    sstable = initStableState()

    state = %{
      # latest term server has seen (initialized to 0 on first boot, increases monotonically)
      # int that increments everytime new leader election happens
      currentTerm: sstable.currentTerm,

      # candidateId that received vote in current term (or null if none)
      votedFor: sstable.votedFor,

      # Replicated log ( has )
      log: sstable.log,

      # how far we have commited (or agrred) along the log with the rest of the nodes
      commitLength: sstable.commitLength,

      # index of highest log entry known to be committed (initialized to 0, increases monotonically)
      commitIndex: 0,

      # index of highest log entry applied to state machine (initialized to 0, increases monotonically)
      lastApplied: 0,

      # current role (always a follower at first start)
      currentRole: :follower,
      votesReceived: nil,
      sentLength: nil,
      ackedLength: nil,
      peers: []
    }

    Logger.debug("state: #{inspect(state)}")
    state
  end

  def initStableState do
    # First look for disk state, if nothing, initialise new sState and return

    case SStable.fetch() do
      {:ok, stateFromFile} ->
        Logger.info("Found stable state on disk dated: #{stateFromFile.lastWriteUTC}")
        Logger.debug("Previous State on disk: #{stateFromFile.data}")
        stateFromFile.data

      {:error, :enoent} ->
        Logger.info("No stable state on disk found. Initialising to defaults")

        %{
          currentTerm: 0,
          votedFor: nil,
          log: [],
          commitLength: 0
        }
    end
  end
end

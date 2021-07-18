defmodule Raft.InitStateVar do
  require Logger

  alias Raft.{
    SStable,
    Configurations
  }

  def initVariables() do
    sstable = initStableState()

    state = %{
      # latest term server has seen (initialized to 0 on first boot, increases monotonically)
      # int that increments everytime new leader election happens
      current_term: sstable.current_term,

      # candidateId that received vote in current term (or null if none)
      voted_for: sstable.voted_for,

      # Replicated log ( has )
      log: sstable.log,

      # how far we have commited (or agrred) along the log with the rest of the nodes
      commit_length: sstable.commit_length,

      # index of highest log entry known to be committed (initialized to 0, increases monotonically)
      commit_index: 0,

      # index of highest log entry applied to state machine (initialized to 0, increases monotonically)
      last_applied: 0,

      # current role (always a follower at first start)
      current_role: :follower,
      votes_received: [],
      sent_length: nil,
      acked_length: nil,
      current_leader: nil,
      peers: %Configurations{}.peers,
      cluster_size: Enum.count(%Configurations{}.peers)
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
          current_term: 0,
          voted_for: nil,
          log: [],
          commit_length: 0
        }
    end
  end
end

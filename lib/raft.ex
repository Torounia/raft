defmodule Raft do
  alias Raft.{
    InitStateVar,
    MessageProcessor
  }

  require Logger

  def init do
    Logger.info("Starting Raft consensus module")
    Logger.info("Starting Raft Supervisor")
    Logger.info("Initialising persistent state variables")
    state = InitStateVar.initVariables()
    Logger.debug("Persistent state variables: #{inspect(state)}")
    Logger.debug("Starting Communication Layer")
    {:ok, pid} = MessageProcessor.startServer(state)
    Logger.info("Communication Layer started with pid: #{inspect(pid)}")
  end


end

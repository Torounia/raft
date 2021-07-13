defmodule Raft do
  @doc """
  External facing module. Should have functions: init, write/ read log, system status
  """
  alias Raft.{
    InitStateVar,
    Supervisor
  }

  require Logger

  def init do

    Logger.info("Starting Raft consensus module")
    Logger.info("Starting Raft Supervisor #TODO")
    Logger.info("Initialising state")
    state = InitStateVar.initVariables()
    Logger.info("Starting Supervisor")
    case Supervisor.startSupervisor(state) do
      {:ok, pid} -> Logger.info("Supervisor started. pid: #{inspect(pid)}")
      {:error, {:already_started, pid}} -> Logger.info("Supervisor already started. pid: #{inspect(pid)}")
    end
    Logger.info("Supervisor children: #{inspect(Supervisor.which_children())}")


  end


end

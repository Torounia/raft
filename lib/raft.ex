defmodule Raft do
  @doc """
  External facing module. Should have functions: init, write/ read log, system status
  """
  alias Raft.{
    InitStateVar,
    Supervisor,
    MessageProcessing.Main
  }

  require Logger

  def init do

    Logger.info("Starting Raft consensus module")
    Logger.info("Initialising state")
    state = InitStateVar.initVariables()
    Logger.info("Starting Supervisor")
    case Supervisor.startSupervisor(state) do
      {:ok, pid} -> Logger.info("Supervisor started. pid: #{inspect(pid)}")
      {:error, {:already_started, pid}} -> Logger.info("Supervisor already started. pid: #{inspect(pid)}")
    end

    {:ok, supervisor_children} = Supervisor.which_children()
    if Enum.count(supervisor_children) == 4 do
      Logger.debug("Supervisor children: #{inspect(supervisor_children)}")

    else
      Logger.error("Error, not all children processes started properly.")
    end


  end

  def start do
    Main.first_time_run()
  end

  def add_new_cmd(cmd) do
    Main.new_entry(cmd)
  end

end

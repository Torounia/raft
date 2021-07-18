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
    #state = %{state | log: [%Raft.LogEnt{index: 1, term: 1, cmd: "test"} | state.log] |> Enum.reverse()}
    #state = %{state | log: [%Raft.LogEnt{index: 2, term: 2, cmd: "test2"} | state.log] |> Enum.reverse()}
    Logger.info("Starting Supervisor")
    case Supervisor.startSupervisor(state) do
      {:ok, pid} -> Logger.info("Supervisor started. pid: #{inspect(pid)}")
      {:error, {:already_started, pid}} -> Logger.info("Supervisor already started. pid: #{inspect(pid)}")
    end

    {:ok, supervisor_children} = Supervisor.which_children()
    if Enum.count(supervisor_children) == 3 do
      Logger.debug("Supervisor children: #{inspect(supervisor_children)}")

    else
      Logger.error("Error, not all children processes started properly. restarting supervisor..")
      #TODO restart supervisor
    end


  end

  def start do
    Main.first_time_run()
  end

end

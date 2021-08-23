defmodule Raft do
  @moduledoc """
  Main Raft Module. Entry point of the application. Contains the initialisation function, and other Raft control functions.
  TODO: Move init() to another module
  """

  alias Raft.{
    InitStateVar,
    Supervisor,
    MessageProcessing.Main
  }

  require Logger

  def init(nodes) do

    Logger.info("Starting Raft consensus module")
    Logger.info("Initialising state")
    state = InitStateVar.initVariables(nodes)
    Logger.info("Starting Supervisor")
    supervisor_state = Supervisor.startSupervisor(state)

    case supervisor_state do
      {:ok, pid} -> Logger.info("Supervisor started. pid: #{inspect(pid)}")
      {:error, {:already_started, pid}} -> Logger.info("Supervisor already started. pid: #{inspect(pid)}")
    end

    {:ok, supervisor_children} = Supervisor.which_children()
    if Enum.count(supervisor_children) == 5 do
      Logger.debug("Supervisor children: #{inspect(supervisor_children)}")

    else
      Logger.error("Error, not all children processes started properly.")
    end

    supervisor_state
  end

  def start do
    Main.first_time_run()
  end

  def add_to_log(cmd) do
    Main.new_entry(cmd, Node.self())
  end

  def current_state() do
    state = Main.show_current_state()
    Logger.info(inspect(state))
  end

  def current_leader() do
    state = Main.show_current_state()
    Logger.info(inspect(state.current_leader))
  end

  def current_log() do
    state = Main.show_current_state()
    Logger.info(inspect(state.log))
  end

end

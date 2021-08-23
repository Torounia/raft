defmodule Raft.Test do
  @moduledoc """
  Module to hold the raft testing code.

  Tests:

  """
  use GenServer
  require Logger
  alias Raft.ClusterConfig, as: ClusterConfig

  def init_test(state) do
    Logger.debug("Starting Testing GenServer")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def show_current_state() do
    state = GenServer.call(__MODULE__, :show_current_state)
    state
  end

  def add_to_log(start_timestamp, source, dest, msg) do
    case :global.whereis_name(dest) do
      :undefined ->
        Logger.debug("Cannot find #{inspect(dest)} in the cluster")

      pid ->
        Logger.debug(
          "Sending #{inspect(msg)} to #{inspect(dest)} @ #{inspect(:global.whereis_name(dest))}"
        )

        GenServer.cast(__MODULE__, {:add_new_log_start_timestamp, start_timestamp})
        GenServer.cast(pid, {:sendMsg, source, msg})
    end
  end

  def send_msg(source, dest, msg) do
    case :global.whereis_name(dest) do
      :undefined ->
        Logger.debug("Cannot find #{inspect(dest)} in the cluster")

      pid ->
        Logger.debug(
          "Sending #{inspect(msg)} to #{inspect(dest)} @ #{inspect(:global.whereis_name(dest))}"
        )

        GenServer.cast(pid, {:sendMsg, source, msg})
    end
  end

  def start_raft(request_time, source, dest) do
    case :global.whereis_name(dest) do
      :undefined ->
        Logger.info("Cannot find #{inspect(dest)} in the cluster")

      pid ->
        Logger.info(
          "Sending :start_raft to #{inspect(dest)} @ #{inspect(:global.whereis_name(dest))}"
        )

        GenServer.cast(__MODULE__, {:start_raft_start_timestamp, request_time})
        GenServer.cast(pid, {:sendMsg, source, {:startProtocol, Node.self()}})
    end
  end

  def terminate_nodes() do
    GenServer.cast(__MODULE__, :broadcast_terminate)
  end

  def request_state() do
    GenServer.cast(__MODULE__, :request_state)
  end

  def init(state) do
    ClusterConfig.init(state)
    state = Map.put(state, :other_servers_state, %{})
    {:ok, state}
  end

  def handle_call(:show_current_state, _from, state) do
    # Logger.info("Current state: #{inspect(state)}")
    {:reply, state, state}
  end

  def handle_cast({:sendMsg, source, {:state_report, {r_source, r_state}}}, state) do
    Logger.info("Received state from #{inspect(source)}. Saving in to test state.")

    state = %{
      state
      | other_servers_state: Map.put(state.other_servers_state, r_source, r_state)
    }

    {:noreply, state}
  end

  def handle_cast({:sendMsg, source, msg}, state) do
    Logger.debug("Received msg #{inspect(msg)} from #{inspect(source)}.")

    case msg do
      {:ok_commited, cmd} ->
        Logger.info(
          " Command #{inspect(cmd)} is commited to the Raft Log. Elapsed time: #{
            inspect(Time.diff(Time.utc_now(), state.add_new_log_start_timestamp, :millisecond))
          } "
        )

      {:leader, peer} ->
        Logger.info(
          " Leader #{inspect(peer)} has been elected. Elapsed time: #{
            inspect(Time.diff(Time.utc_now(), state.add_new_log_start_timestamp, :millisecond))
          } "
        )

      {_, msg} ->
        Logger.info("Received unknown message #{inspect(msg)}")
    end

    {:noreply, state}
  end

  def handle_cast({:add_new_log_start_timestamp, start_timestamp}, state) do
    Logger.debug("Adding new_log_msg start_timestamp to state")
    state = Map.put(state, :add_new_log_start_timestamp, start_timestamp)
    {:noreply, state}
  end

  def handle_cast({:start_raft_start_timestamp, start_timestamp}, state) do
    Logger.debug("Starting Raft protocol start_timestamp to state")
    state = Map.put(state, :add_new_log_start_timestamp, start_timestamp)
    {:noreply, state}
  end

  def handle_cast(:broadcast_terminate, state) do
    Logger.info("Broadcasting terminate command to all nodes")
    GenServer.abcast(state.peers, Raft.Comms, {:broadcast, Node.self(), {:terminateNode, []}})
    {:noreply, state}
  end

  def handle_cast(:request_state, state) do
    Logger.info("Broadcasting request_state to all nodes")

    GenServer.abcast(
      state.peers,
      Raft.Comms,
      {:broadcast, Node.self(), {:report_state, Node.self()}}
    )

    {:noreply, state}
  end
end

defmodule Test.Helpers do
  require Logger

  def start_election_specific_node(node) do
    Logger.info("Starting Raft election on #{inspect(node)} Node")
    Raft.Test.start_election(node)
    node_state = request_state(node)

    Logger.info(
      "Election completed - new leader: #{inspect(node_state.current_leader)}, current term = #{
        inspect(node_state.current_term)
      }, duration:#{inspect(node_state.runtime_stats.last_election_duration)} ms"
    )

    :timer.sleep(2000)
  end

  def request_state(node \\ :all) do
    :timer.sleep(2000)
    Logger.debug("Requesting state from node(s)")
    Raft.Test.request_state(node)
    :timer.sleep(2000)
    state_from_other_nodes = Raft.Test.show_current_state()

    case node do
      :all -> state_from_other_nodes.other_servers_state
      not_nil -> Map.get(state_from_other_nodes.other_servers_state, not_nil)
    end
  end

  def new_log_entry(cmd, node) do
    Raft.Test.add_to_log(
      Time.utc_now(),
      Node.self(),
      node,
      {:logNewEntry, {cmd, Node.self()}}
    )
  end

  def add_5_entries_single_term() do
    cluster_nodes = Raft.Test.show_current_state().peers
    node = Enum.random(cluster_nodes)

    sample_entries =
      for n <- 1..5 do
        :timer.sleep(500)
        cmd = "test_entry_#{n}"
        Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
        new_log_entry(cmd, node)
        cmd
      end

    sample_entries
  end

  def add_3_entries_3_terms() do
    for term <- 1..3 do
      new_election_random_node()
      cluster_nodes = Raft.Test.show_current_state().peers
      node = Enum.random(cluster_nodes)

      for n <- 1..3 do
        cmd = "test_entry_#{n}_term_#{term}"
        Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
        new_log_entry(cmd, node)
        :timer.sleep(500)
      end

      Logger.info(
        "Finished adding entries for term #{inspect(term)}. Requesting new election to change term number."
      )
    end
  end

  def new_election_random_node() do
    Logger.info("Choosing random node for new election")
    :timer.sleep(1000)
    cluster_nodes = Raft.Test.show_current_state().peers
    current_raft_state = request_state(Enum.random(cluster_nodes))

    if current_raft_state.current_leader != nil do
      list_of_nodes_not_leader =
        Enum.filter(current_raft_state.peers, fn node ->
          node != current_raft_state.current_leader
        end)

      random_leader = Enum.random(list_of_nodes_not_leader)
      start_election_specific_node(random_leader)
      random_leader
    else
      random_leader = Enum.random(cluster_nodes)
      start_election_specific_node(random_leader)
      random_leader
    end
  end

  def terminate_nodes() do
    Raft.Test.terminate_nodes()
  end

  def reboot_nodes() do
    Raft.Test.reboot_nodes()
  end
end

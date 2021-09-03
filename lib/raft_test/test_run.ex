defmodule Test do
  require Logger

  def init(nodes) do
    Logger.debug("Initialising Test framework")
    state = %{peers: nodes}
    Raft.Test.init_test(state)
  end

  def test1() do
    Logger.info("Election Safety Test. At most one leader can be elected in a given term")

    start_election(:peer1@localhost)

    other_nodes_state = request_state()

    for {peer, state} <- other_nodes_state do
      Logger.info(
        "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, Leader: #{
          inspect(state.current_leader)
        }, Last election duration: #{inspect(state.runtime_stats.last_election_duration)} ms"
      )
    end

    :timer.sleep(2000)
    Logger.info("Test End")
  end

  def test2() do
    Logger.info(
      "Leader Append-Only: a leader never overwrites or deletes entries in its log; it only appends new entries."
    )

    start_election(:peer1@localhost)

    add_5_entries_single_term()

    other_nodes_state = request_state()

    Logger.info("Printing current log on leader state")

    for {peer, state} <- other_nodes_state do
      if state.current_leader == peer do
        Logger.info(
          "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, log: #{inspect(state.log)}"
        )
      end
    end

    :timer.sleep(2000)
    Logger.info("Test End")
  end

  def test3() do
    Logger.info("Log Matching: if two logs contain an entry with the same
      index and term, then the logs are identical in all entries
      up through the given index.")

    start_election(:peer1@localhost)

    add_3_entries_3_terms()

    other_nodes_state = request_state()

    # Logger.info("Comparing a random log entity from two logs")

    # peer1_log = Map.get(other_nodes_state, :peer1@localhost) |> Map.get(:log)

    # peer2_log = Map.get(other_nodes_state, :peer2@localhost) |> Map.get(:log)

    # Logger.info("Peer1 log: #{inspect(peer1_log)}")

    for {peer, state} <- other_nodes_state do
      Logger.info(
        "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, log: #{inspect(state.log)}"
      )
    end

    :timer.sleep(2000)
    Logger.info("Test End")
  end

  def test4() do
    Logger.info(
      "Leader Completeness Test. If a log entry is committed in a given term,
            then that entry will be present in the logs of the leaders for all higher-numbered terms."
    )
  end

  defp start_election(node) do
    Logger.info("Starting Raft election on #{inspect(node)} Node")
    Raft.Test.start_raft(node)
    node_state = request_state(node)

    Logger.info(
      "Election completed - new leader: #{inspect(node_state.current_leader)}, current term = #{
        inspect(node_state.current_term)
      }"
    )

    :timer.sleep(2000)
  end

  defp request_state(node \\ :all) do
    :timer.sleep(2000)
    Logger.info("Requesting state from node(s)")
    Raft.Test.request_state(node)
    :timer.sleep(2000)
    state_from_other_nodes = Raft.Test.show_current_state()

    case node do
      :all -> state_from_other_nodes.other_servers_state
      not_nil -> Map.get(state_from_other_nodes.other_servers_state, not_nil)
    end
  end

  defp new_log_entry(cmd) do
    Raft.Test.add_to_log(
      Time.utc_now(),
      Node.self(),
      :peer1@localhost,
      {:logNewEntry, {cmd, Node.self()}}
    )
  end

  defp add_5_entries_single_term() do
    for n <- 1..5 do
      cmd = "test_entry_#{n}"
      Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
      new_log_entry(cmd)
      :timer.sleep(1000)
    end
  end

  defp add_3_entries_3_terms() do
    for term <- 1..3 do
      for n <- 1..3 do
        cmd = "test_entry_#{n}_term_#{term}"
        Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
        new_log_entry(cmd)
        :timer.sleep(500)
      end

      Logger.info(
        "Finished adding entries for term #{inspect(term)}. Requesting new election to increase term."
      )

      :timer.sleep(1000)
      current_raft_state = request_state(:peer1@localhost)

      list_of_nodes_not_leader =
        Enum.filter(current_raft_state.peers, fn node ->
          node != current_raft_state.current_leader
        end)

      random_leader = Enum.random(list_of_nodes_not_leader)
      start_election(random_leader)
    end
  end

  defp terminate_raft() do
    Raft.Test.terminate_nodes()
  end
end

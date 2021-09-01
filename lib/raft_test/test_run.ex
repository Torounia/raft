defmodule Test do
  require Logger

  def init(nodes) do
    Logger.debug("Initialising Test framework")
    state = %{peers: nodes}
    Raft.Test.init_test(state)
  end

  def test1() do
    Logger.info("Election Safety Test. At most one leader can be elected in a given term")
    Logger.info("Starting Raft Protocol")
    start_raft()
    :timer.sleep(2000)
    Logger.info("Requesting state from all nodes")
    Raft.Test.request_state()
    :timer.sleep(2000)
    Logger.info("Printing current leader on all nodes")
    test_state = Raft.Test.show_current_state()

    for {peer, state} <- test_state.other_servers_state do
      Logger.info(
        "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, Leader: #{
          inspect(state.current_leader)
        }, Last election duration: #{inspect(state.runtime_stats.last_election_duration)} ms"
      )
    end

    :timer.sleep(6000)
    Logger.info("Test End")
  end

  def test2() do
    Logger.info(
      "Leader Append-Only: a leader never overwrites or deletes entries in its log; it only appends new entries."
    )

    Logger.info("Starting Raft Protocol")
    start_raft()
    :timer.sleep(2000)

    for n <- 1..5 do
      cmd = "test_entry_#{n}"
      Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
      new_log_entry(cmd)
      :timer.sleep(1000)
    end

    :timer.sleep(2000)
    Logger.info("Requesting state from all nodes")
    Raft.Test.request_state()
    :timer.sleep(2000)
    test_state = Raft.Test.show_current_state()

    Logger.info("Printing current log on leader state")

    for {peer, state} <- test_state.other_servers_state do
      if state.current_leader == peer do
        Logger.info(
          "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, log: #{inspect(state.log)}"
        )
      end
    end

    :timer.sleep(6000)
    Logger.info("Test End")
  end

  def test4() do
    Logger.info(
      "Leader Completeness Test. If a log entry is committed in a given term,
            then that entry will be present in the logs of the leaders for all higher-numbered terms."
    )

    for n <- 1..5 do
      cmd = "test_entry_#{n}"
      Logger.info("Adding sample entries to the Log. Entry # #{n}: #{inspect(cmd)}")
      new_log_entry(cmd)
      :timer.sleep(1000)
    end

    # :timer.sleep(2000)
    # Raft.Test.request_state()
    # :timer.sleep(2000)
    # test_state = Raft.Test.show_current_state()

    # for {peer, state} <- test_state.other_servers_state do
    #   Logger.info(
    #     "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, Leader: #{
    #       inspect(state.current_leader)
    #     }, Log:#{inspect(state.log)} "
    #   )
    # end

    # :timer.sleep(2000)
    # Logger.info("Requesting new leader election")
    # Raft.Test.send_msg(Node.self(), :peer2@localhost, {:newLeader, Node.self()})
    # Logger.info("Requesting new state from each peer")
    # Raft.Test.request_state()
    # :timer.sleep(2000)
    # test_state = Raft.Test.show_current_state()

    # for {peer, state} <- test_state.other_servers_state do
    #   Logger.info(
    #     "Peer #{inspect(peer)}, Term: #{inspect(state.current_term)}, Leader: #{
    #       inspect(state.current_leader)
    #     }, Log:#{inspect(state.log)} "
    #   )
    # end
  end

  defp terminate_raft() do
    Raft.Test.terminate_nodes()
  end

  defp start_raft() do
    Raft.Test.start_raft(:peer1@localhost)
  end

  defp new_log_entry(cmd) do
    Logger.info("Adding new entry to the Log. Timestamp: #{inspect(Time.utc_now())}")

    Raft.Test.add_to_log(
      Time.utc_now(),
      Node.self(),
      :peer1@localhost,
      {:logNewEntry, {cmd, Node.self()}}
    )
  end
end

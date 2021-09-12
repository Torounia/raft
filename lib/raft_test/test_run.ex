defmodule Test do
  require Logger
  import Test.Helpers

  def init(nodes) do
    Logger.debug("Initialising Test framework")
    state = %{peers: nodes}
    Raft.Test.init_test(state)
  end

  def test1() do
    Logger.info("Leader Election Duration Test")

    total_cluster_nodes = Enum.count(Raft.Test.show_current_state().peers)

    Logger.info("Starting test")

    test_result =
      for test_round <- 1..3 do
        random_leader = new_election_random_node()

        other_nodes_state = request_state(random_leader)

        Logger.debug(
          "duration for election round: #{inspect(test_round)}, cluster size: #{
            inspect(total_cluster_nodes)
          }, duration:#{inspect(other_nodes_state.runtime_stats.last_election_duration)}"
        )

        other_nodes_state.runtime_stats.last_election_duration
      end

    if Enum.any?(test_result, fn x -> x != nil end) do
      ave = Enum.reduce(test_result, fn x, acc -> x + acc end) / 3

      Logger.info(
        "Average duration for election round: #{inspect(ave)}ms, cluster size: #{
          inspect(total_cluster_nodes)
        }"
      )
    else
      Logger.info("Test Failed. Not all rounds completed or wrong leader. See logs
        }")
    end

    Logger.info("Test End")
  end

  def test2() do
    Logger.info("Commiting entry to log Duration Test")
    random_leader = new_election_random_node()
    total_cluster_nodes = Enum.count(Raft.Test.show_current_state().peers)
    Logger.info("Starting Election on: #{inspect(random_leader)}")

    new_log_entry("Test_1", random_leader)

    test_result =
      for test_round <- 1..3 do
        cmd = "Test_#{test_round}"
        new_log_entry(cmd, random_leader)

        {cmd_sent_time, cmd_out} = Raft.Test.show_current_state().add_new_log_start_timestamp

        Logger.debug("Command #{inspect(cmd_out)} is sent to be commited on: #{cmd_sent_time}.")

        :timer.sleep(1000)
        {cmd_commit_time, cmd_commit} = Raft.Test.show_current_state().add_new_log_stop_timestamp

        Logger.debug("Command #{inspect(cmd_commit)} is commited. timestamp: #{cmd_commit_time}.")

        if cmd_out == cmd_commit do
          Logger.debug("Commands match")

          Logger.info(
            "Duration of commit round for entry #{inspect(cmd_out)} is #{
              inspect(Time.diff(cmd_commit_time, cmd_sent_time, :millisecond))
            }ms"
          )

          Time.diff(cmd_commit_time, cmd_sent_time, :millisecond)
        else
          Logger.debug("Error, commands don't match")
          nil
        end
      end

    if Enum.any?(test_result, fn x -> x != nil end) do
      ave = Enum.reduce(test_result, fn x, acc -> x + acc end) / 3

      Logger.info(
        "Average duration for entry to be commited: #{inspect(ave)}ms, cluster size: #{
          inspect(total_cluster_nodes)
        }"
      )
    else
      Logger.info("Test Failed. There are nil commit rounds. See logs
          }")
    end

    Logger.info("Test End")
  end

  def test3() do
    Logger.info("Election Safety Test. At most one leader can be elected in a given term")

    test_rounds = 3
    test_result_acc = []
    total_cluster_nodes = Enum.count(Raft.Test.show_current_state().peers)

    test_result =
      for test_round <- 1..test_rounds do
        Logger.info("Starting test round #{inspect(test_round)} of 3")

        random_leader = new_election_random_node()
        round_result_acc = []

        Logger.info(
          "Round: #{inspect(test_round)}, Random leader choosen: #{inspect(random_leader)}"
        )

        other_nodes_state = request_state()

        round_result =
          for {peer, state} <- other_nodes_state do
            peer_result =
              if state.current_leader == random_leader do
                Logger.debug("Peer #{inspect(peer)} has leader #{inspect(state.current_leader)}")

                peer
              else
                Logger.debug("Peer #{inspect(peer)} has leader #{inspect(state.current_leader)}")

                false
              end

            round_result_acc =
              if peer_result do
                round_result_acc ++ [peer_result]
              else
                round_result_acc
              end

            round_result_acc
          end

        Logger.debug("round_result = #{inspect(round_result)}")

        test_result_acc =
          if Enum.count(round_result) == total_cluster_nodes do
            Logger.info(
              "Election Safety Test Pass for round #{inspect(test_round)} with leader #{
                inspect(random_leader)
              }"
            )

            test_result_acc ++ [:pass]
          else
            Logger.info(
              "Election Safety Test Failed for round #{inspect(test_round)} with leader #{
                inspect(random_leader)
              }"
            )

            test_result_acc
          end

        test_result_acc
      end

    Logger.debug("test_result = #{inspect(test_result)}")

    if Enum.count(test_result) == test_rounds do
      Logger.info("Election Safety Test Pass for all rounds")
    else
      Logger.info("Election Safety Test Failed for all rounds")
    end

    Logger.info("Test End")
  end

  def test4() do
    Logger.info(
      "Leader Append-Only: a leader never overwrites or deletes entries in its log; it only appends new entries."
    )

    Logger.info("Starting test")
    new_election_random_node()

    sample_added_to_log = add_5_entries_single_term()
    Logger.debug("Sample entries to the log: #{inspect(sample_added_to_log)}")
    sample_added_to_log_length = Enum.count(sample_added_to_log)
    other_nodes_state = request_state()

    leader_log =
      for {peer, state} <- other_nodes_state do
        if state.current_leader == peer do
          Logger.debug("#{inspect(peer)} is leader - log: #{inspect(state.log)}")
          state.log
        else
          nil
        end
      end

    leader_log = Enum.find(leader_log, nil, fn n -> n != nil end)

    log_result =
      case leader_log do
        nil ->
          Logger.info("Error, no log found")

        log ->
          for index <- 0..(sample_added_to_log_length - 1) do
            sample_entry = Enum.fetch!(sample_added_to_log, index)
            log_entry = Enum.fetch!(log, index)

            Logger.debug(
              "Sample Entry = #{inspect(sample_entry)}, log Entry = #{inspect(log_entry)}"
            )

            if sample_entry == log_entry.cmd do
              Logger.info(
                "Sample entry #{inspect(sample_entry)} match log entry #{inspect(log_entry)}"
              )

              true
            else
              Logger.debug(
                "Sample entry #{inspect(sample_entry)} does not match log entry #{
                  inspect(log_entry)
                }"
              )

              false
            end
          end
      end

    log_result = Enum.filter(log_result, fn n -> n != false end)
    Logger.debug("log_result: #{inspect(log_result)}")

    if Enum.count(log_result) == sample_added_to_log_length do
      Logger.info("Leader Append only test Pass")
    else
      Logger.info("Leader Append only test Failed. See debug logs")
      Logger.debug("Leader Append only test Failed. Result: #{inspect(log_result)}")
    end

    Logger.info("Test End")
  end

  def test5() do
    Logger.info(" Log Matching: if two logs contain an entry with the same
                  index and term, then the logs are identical in all entries
                  up through the given index.")

    add_3_entries_3_terms()

    other_nodes_state = request_state()

    Logger.info("Selecting two nodes randomly to compare log")

    random_nodes = Enum.take_random(other_nodes_state, 2)

    {node_a, node_a_log} = Enum.fetch!(random_nodes, 0)

    {node_b, node_b_log} = Enum.fetch!(random_nodes, 1)

    Logger.info(
      " Random nodes are: #{inspect(node_a)} and #{inspect(node_b)}. Comparing entries..."
    )

    valid_counter =
      for n <- 0..8 do
        entry_a = Enum.fetch!(node_a_log.log, n)
        entry_b = Enum.fetch!(node_b_log.log, n)

        if(entry_a == entry_b) do
          Logger.debug(
            "Entry #{inspect(entry_a)} with index #{inspect(n)} is the same with #{
              inspect(entry_b)
            }"
          )

          Logger.info("Entries with index #{inspect(n)} match")
          true
        else
          Logger.debug(
            "Entry #{inspect(entry_a)} with index #{inspect(n)} is NOT the same with #{
              inspect(entry_b)
            }"
          )

          Logger.info("Entries with index #{inspect(n)} don't match")

          false
        end
      end

    valid_counter = Enum.filter(valid_counter, fn n -> n != false end)
    Logger.debug("#{inspect(valid_counter)}")

    if Enum.count(valid_counter) == 9 do
      Logger.info("Test Log Matching Passed")
    else
      Logger.info("Test Log Matching Failed. See debug logs")
    end

    Logger.info("Test End")
  end

  def test6() do
    Logger.info(
      "Leader Completeness Test. If a log entry is committed in a given term,
            then that entry will be present in the logs of the leaders for all higher-numbered terms."
    )

    Logger.info("Starting test")

    new_election_random_node()

    sample_added_to_log = add_5_entries_single_term()

    random_log_entry = Enum.random(sample_added_to_log)

    other_nodes_state = request_state()

    temp =
      for {peer, state} <- other_nodes_state do
        if state.current_leader == peer do
          Logger.debug("#{inspect(peer)} is leader - state: #{inspect(state.log)}")
          {peer, state, state.log}
        else
          nil
        end
      end

    {leader, leader_state, leader_log} = Enum.find(temp, nil, fn n -> n != nil end)
    Logger.debug("leader: #{inspect(leader)}")
    Logger.debug("leader state: #{inspect(leader_state)}")
    Logger.debug("leader log: #{inspect(leader_log)}")

    first_term =
      case leader_log do
        nil ->
          Logger.info("Error, no log found")

        log ->
          for index <- 0..4 do
            log_entry = Enum.fetch!(log, index)

            if random_log_entry == log_entry.cmd do
              Logger.info(
                "Random selected entry #{inspect(random_log_entry)} is in #{inspect(leader)} with term #{
                  inspect(leader_state.current_term)
                } and index #{inspect(index)}"
              )

              true
            else
              Logger.debug(
                "Sample entry #{inspect(random_log_entry)} was not found in #{inspect(log_entry)}"
              )

              false
            end
          end
      end

    Logger.info("Requesting new election")
    new_election_random_node()

    other_nodes_state = request_state()

    temp =
      for {peer, state} <- other_nodes_state do
        if state.current_leader == peer do
          Logger.debug("#{inspect(peer)} is leader - state: #{inspect(state.log)}")
          {peer, state, state.log}
        else
          nil
        end
      end

    {leader, leader_state, leader_log} = Enum.find(temp, nil, fn n -> n != nil end)

    second_term =
      case leader_log do
        nil ->
          Logger.info("Error, no log found")

        log ->
          for index <- 0..4 do
            log_entry = Enum.fetch!(log, index)

            if random_log_entry == log_entry.cmd do
              Logger.info(
                "Random selected entry #{inspect(random_log_entry)} commited in leader #{
                  inspect(leader)
                } with term #{inspect(leader_state.current_term)} and index #{inspect(index)}"
              )

              true
            else
              Logger.debug(
                "Sample entry #{inspect(random_log_entry)} was not found in #{inspect(log_entry)}"
              )

              false
            end
          end
      end

    if Enum.find(first_term, false, fn n -> n == true end) and
         Enum.find(second_term, false, fn n -> n == true end) do
      Logger.info("Leader Completeness Test Passed.")
    else
      Logger.info("Leader Completeness Test Failed.")
    end

    Logger.info("Test End")
  end
end

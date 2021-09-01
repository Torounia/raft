defmodule Client do
  require Logger

  def init(nodes) do
    Logger.debug("Initialising Client Agent")
    Raft.Client.startClient(nodes)
  end

  def new_log_entry(cmd) do
    Logger.info("Adding new entry to the Log. Timestamp: #{inspect(Time.utc_now())}")

    Raft.Client.add_to_log(
      Time.utc_now(),
      Node.self(),
      :peer1@localhost,
      {:logNewEntry, {cmd, Node.self()}}
    )
  end
end

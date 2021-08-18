defmodule Client do
  def init() do
    Raft.Client.startClient()
  end

  def new_log_entry(cmd) do
    Raft.Client.send_msg(
      Node.self(),
      :peer1@localhost,
      {:logNewEntry, {cmd, Node.self()}}
    )
  end
end

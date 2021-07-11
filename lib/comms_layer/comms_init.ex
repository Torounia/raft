defmodule Raft.MessageProcessing.ClusterConfig do
  @doc """
  Functions related to cluster management
  """
  require Logger

  def init do
    # Logger.debug("Setting up cookie")
    # Node.set_cookie(%Raft.Config{}.cookie)
    nodesNotSelf = Enum.filter(%Raft.Config{}.peers, fn node -> node != Node.self() end)
    Logger.debug("Conneting to other nodes")

    Enum.each(nodesNotSelf, fn node ->
      if Node.connect(node) do
        Logger.debug("Connected to #{inspect(node)}")
      else
        Logger.debug("Cannot establish connection with #{inspect(node)}")
      end
    end)

    Logger.info("Connected to nodes: #{inspect(Node.list())}")
  end
end

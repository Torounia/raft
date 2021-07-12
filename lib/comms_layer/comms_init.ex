defmodule Raft.ClusterConfig do
  @doc """
  Functions related to cluster management
  """
  require Logger

  def init do
    # Logger.debug("Setting up cookie")
    # Node.set_cookie(%Raft.Config{}.cookie)
    Logger.debug("Registering Global name and syncing..")
    :global.register_name(String.to_atom(Atom.to_string(Node.self()) <> "_comms"), self())
    :global.sync()
    Logger.debug("Other globally registered nodes: #{inspect(:global.registered_names())}")

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
    Atom.to_string(Node.self())
  end
end

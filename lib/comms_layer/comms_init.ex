defmodule Raft.ClusterConfig do
  @doc """
  Functions related to cluster communication management
  """
  require Logger

  def init(state) do
    Logger.debug("Registering Global name and syncing..")

    :global.register_name(Node.self(), self())
    :global.sync()
    Logger.debug("Other globally registered nodes: #{inspect(:global.registered_names())}")

    nodes_not_self = Enum.filter(state.peers, fn node -> node != Node.self() end)
    Logger.debug("Conneting to other nodes")

    Enum.each(nodes_not_self, fn node ->
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

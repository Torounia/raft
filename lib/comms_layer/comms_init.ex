defmodule Raft.ClusterConfig do
  @doc """
  Functions related to cluster communication management
  """
  require Logger

  def init(state) do
    nodes_not_self = Enum.filter(state.peers, fn node -> node != Node.self() end)
    Logger.debug("Conneting to other nodes")

    random_node = Enum.random(nodes_not_self)

    if Node.connect(random_node) do
      Logger.debug("Connected to #{inspect(random_node)}")
    else
      Logger.debug(
        "Cannot establish connection with #{inspect(random_node)}. Trying again with different node"
      )

      :timer.sleep(1000)
      Node.connect(Enum.random(nodes_not_self))
    end

    :timer.sleep(2000)
    Logger.info("Connected to nodes: #{inspect(Node.list())}")
    Logger.debug("Registering Global name and syncing..")

    :global.register_name(Node.self(), self())
    :global.sync()
    Logger.info("Other globally registered nodes: #{inspect(:global.registered_names())}")

    Atom.to_string(Node.self())
  end
end

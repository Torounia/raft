defmodule Raft.Init do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting Raft Application")

    Logger.debug("Reading enviroment variables")
    start_type = System.get_env("run_env")

    state =
      case start_type do
        "test_3" ->
          Logger.info("Starting Raft in testing mode")
          init(3)

        "test_5" ->
          Logger.info("Starting Raft in testing mode")
          init(5)

        "test_7" ->
          Logger.info("Starting Raft in testing mode")
          init(7)

        "normal" ->
          Logger.info("Starting Raft in normal mode")
          init()

        "nerves_test_3" ->
          Logger.info("Starting Raft in normal mode")
          init_nerves(3)

        "nerves_test_5" ->
          Logger.info("Starting Raft in normal mode")
          init_nerves(5)

        "nerves_test_7" ->
          Logger.info("Starting Raft in normal mode")
          init_nerves(7)

        nil ->
          Logger.info("No ENV_VAR found. Starting Raft in normal mode")
          init()

        var ->
          Logger.error("Unknown ENV_VAR value #{inspect(var)}. Shutting down..")
          :init.stop()
      end

    state
  end

  defp init(nodes_int \\ 3) do
    case node_type() do
      :peer ->
        Logger.info("Starting peer node")
        Raft.init(generate_nodes(nodes_int))

      :client ->
        Logger.info("Starting client node")
        Client.init(generate_nodes(nodes_int))
        Supervisor.start_link([], strategy: :one_for_one)

      :test ->
        Logger.info("Starting test node")

        nodes =
          case nodes_int do
            3 -> Application.fetch_env!(:raft, :peers3)
            5 -> Application.fetch_env!(:raft, :peers5)
            7 -> Application.fetch_env!(:raft, :peers7)
          end

        # Test.init(Application.fetch_env!(:raft, :peers))
        Test.init(generate_nodes(nodes_int))
        Supervisor.start_link([], strategy: :one_for_one)
    end
  end

  defp init_nerves(nodes_int) do
    case node_type() do
      :test ->
        Logger.info("Starting test node (nerves)")

        nodes =
          case nodes_int do
            3 -> Application.fetch_env!(:raft, :peers3)
            5 -> Application.fetch_env!(:raft, :peers5)
            7 -> Application.fetch_env!(:raft, :peers7)
          end

        Test.init(nodes)
        Supervisor.start_link([], strategy: :one_for_one)
    end
  end

  defp generate_nodes(nodes) do
    Enum.map(1..nodes, fn x ->
      ("peer" <> Integer.to_string(x) <> "@localhost") |> String.to_atom()
    end)
  end

  defp node_type do
    self = Node.self()
    s_self = Atom.to_string(self)

    type =
      if(String.contains?(s_self, "peer")) do
        :peer
      else
        nil
      end

    type =
      if(String.contains?(s_self, "client")) do
        :client
      else
        type
      end

    type =
      if(String.contains?(s_self, "test")) do
        :test
      else
        type
      end

    type
  end
end

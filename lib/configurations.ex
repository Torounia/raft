defmodule Raft.Configurations do
 @moduledoc """
 Module to hold Raft Runtime configuratuion parameters. Similar to config.json
 """
 @typedoc """
      Type that represents runtime configuration settings for the Raft protocol.
  """
@type settings() :: %Raft.Configurations{min_election_timeout: integer, max_election_timeout: integer, heartbeat_timeout: integer, data_dir: char, peers: list}

  defstruct min_election_timeout: 800,
            max_election_timeout: 1100,
            heartbeat_timeout: 500,
            data_dir: "/stable_storage", # the directory to save the persistant storage #TODO
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost],
            peers_3_local_run_win: [:peer1@localhost, :peer2@localhost, :peer3@localhost],
            peers_3_nerves: [
              :"nerves-9ef5@nerves-9ef5.local",
              :"nerves-9c9e@nerves-9c9e.local",
              :"nerves-9398@nerves-9398.local"
            ]

end

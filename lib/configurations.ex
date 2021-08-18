defmodule Raft.Configurations do
 @moduledoc """
 Module to hold Raft Runtime configuratuion parameters. Similar to config.json
 """
 @typedoc """
      Type that represents runtime configuration settings for the Raft protocol.
  """
@type settings() :: %Raft.Configurations{min_election_timeout: integer, max_election_timeout: integer, heartbeat_timeout: integer, data_dir: char, peers: list}

  defstruct min_election_timeout: 200,
            max_election_timeout: 350,
            heartbeat_timeout: 19,
            data_dir: "/stable_storage", # the directory to save the persistant storage #TODO
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost]
            #peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost,:peer4@localhost,:peer5@localhost,:peer6@localhost]
end

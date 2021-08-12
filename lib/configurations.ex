defmodule Raft.Configurations do

  defstruct min_election_timeout: 150,
            max_election_timeout: 300,
            heartbeat_timeout: 25,
            data_dir: "", # the directory to save the persistant storage #TODO
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost]
end

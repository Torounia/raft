defmodule Raft.Configurations do

  defstruct min_election_timeout: 400,
            max_election_timeout: 600,
            heartbeat_timeout: 100,
            data_dir: "", # the directory to save the persistant storage #TODO
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost]
end

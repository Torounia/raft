defmodule Raft.Configurations do
  defstruct min_election_timeout: 1500,
            max_election_timeout: 3000,
            heartbeat_timeout: 500,
            data_dir: "", # the directory to save the persistant storage
            cookie: :iloveelixir,
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost]
end

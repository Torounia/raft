defmodule Raft.Configurations do
  defstruct min_election_timeout: 2500,
            max_election_timeout: 3000,
            heartbeat_timeout: 50,
            data_dir: "", # the directory to save the persistant storage
            cookie: :iloveelixir,
            peers: [:peer1@localhost, :peer2@localhost, :peer3@localhost]
end

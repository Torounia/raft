defmodule Config do
  defstruct min_election_timeout: 150,
            max_election_timeout: 300,
            heartbeat_timeout: 25,
            data_dir: ""
end

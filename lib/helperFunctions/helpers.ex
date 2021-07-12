defmodule Raft.Helpers do
  def rand_election_timeout do
    Enum.random(150..300)
  end
end

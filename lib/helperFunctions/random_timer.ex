defmodule Raft.RandTimer do
  alias Raft.Configurations

  def rand_election_timeout do
    Enum.random(%Configurations{}.min_election_timeout..%Configurations{}.max_election_timeout)
  end
end

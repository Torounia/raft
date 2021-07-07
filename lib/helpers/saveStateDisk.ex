defmodule Raft.StableStorage do
  def store(state) do
    bin = :erlang.term_to_binary(state)
    File.write!("state.bin", bin)
  end

  def fetch do
    File.read!("state.bin") |> :erlang.binary_to_term()
  end
end

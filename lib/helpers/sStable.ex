defmodule Raft.SStable do
  def store(val) do
    bin = :erlang.term_to_binary(val)
    File.write("sState", bin)
  end

  def fetch do
    val =
      case File.read("sState") do
        {:ok, value} -> value |> :erlang.binary_to_term()
        {:error, :enoent} -> {:error, :enoent}
      end
  end
end

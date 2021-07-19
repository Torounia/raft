defmodule Raft.DETS do
  def store(val) do
    toSave = %{
      lastWriteUTC: DateTime.utc_now(),
      data: val
    }

    bin = :erlang.term_to_binary(toSave)
    # TODO error catcher
    File.write("sState", bin)
  end

  def fetch do
    case File.read("sState") do
      {:ok, value} ->
        {:ok, value |> :erlang.binary_to_term()}

      {:error, :enoent} ->
        {:error, :enoent}
    end
  end
end

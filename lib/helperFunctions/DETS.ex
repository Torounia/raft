defmodule Raft.DETS do
  require Logger

  def store(val) do
    toSave = %{
      lastWriteUTC: DateTime.utc_now(),
      data: val
    }

    bin = :erlang.term_to_binary(toSave)
    # TODO error catcher
    name = "sState" <> Atom.to_string(Node.self())
    File.write(name, bin)
  end

  def fetch do
    name = "sState" <> Atom.to_string(Node.self())

    Logger.debug("Fetching binary file from local storage for #{inspect(name)}")

    case File.read(name) do
      {:ok, value} ->
        {:ok, value |> :erlang.binary_to_term()}

      {:error, :enoent} ->
        {:error, :enoent}
    end
  end
end

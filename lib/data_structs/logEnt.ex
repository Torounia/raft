defmodule Raft.LogEnt do
  defstruct [:term, :cmd]
  @type t :: %__MODULE__{term: non_neg_integer(), cmd: term()}
end

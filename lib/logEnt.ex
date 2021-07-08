defmodule LogEnt do
  defstruct [:index, :term, :cmd]
  @type t :: %__MODULE__{index: non_neg_integer(), term: non_neg_integer(), cmd: term()}
end

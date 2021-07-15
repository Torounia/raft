defmodule Raft.MessageProcessing.Types do
  require Logger
  alias Raft.Timer, as: Timer

  def first_time_run(state) do
    Logger.debug("First time run state is #{inspect(state.currentRole == :follower)}")

    if state.currentRole == :follower do
      Logger.debug("Starting heartbeat timer")
      Timer.start_timer()
    end
  end

  def canditate(_state) do
    IO.puts("starting election")
  end
end

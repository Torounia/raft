defmodule Raft.Timer do
  use GenServer
  require Logger
  alias Raft.MessageProcessor, as: MP
  alias Raft.Helpers, as: Fun

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_timer() do
    GenServer.call(__MODULE__, :start_timer)
  end

  def reset_timer() do
    GenServer.call(__MODULE__, :reset_timer)
  end

  def init(%{}) do
    {:ok, %{}}
  end

  def handle_call(:start_timer, _from, %{}) do
    timeout = Fun.rand_election_timeout()
    IO.puts(timeout)
    timer = Process.send_after(self(), :work, timeout)
    {:reply, :ok, %{timer: timer}}
  end

  def handle_call(:reset_timer, _from, %{timer: timer}) do
    :timer.cancel(timer)
    timeout = Fun.rand_election_timeout()
    timer = Process.send_after(self(), :work, timeout)
    {:reply, :ok, %{timer: timer}}
  end

  def handle_info(:work, _state) do
    IO.puts("times up!")
    timeout = Fun.rand_election_timeout()
    IO.puts("New timout: #{timeout}")
    timer = Process.send_after(self(), :work, timeout)

    {:noreply, %{timer: timer}}
  end

  # So that unhanded messages don't error
  def handle_info(_, state) do
    {:ok, state}
  end
end

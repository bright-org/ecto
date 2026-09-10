defmodule Ecto.UUID.Clock do
  @moduledoc false

  # Serializes monotonic UUID v7 timestamps when :atomics/:persistent_term
  # are unavailable (AtomVM). Serialization gives the same ascending guarantee
  # as compare-and-swap under concurrency.

  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  @doc false
  def next_ascending(minimal_step) when is_integer(minimal_step) and minimal_step > 0 do
    GenServer.call(__MODULE__, {:next_ascending, minimal_step})
  end

  @impl true
  def init(previous_ts), do: {:ok, previous_ts}

  @impl true
  def handle_call({:next_ascending, minimal_step}, _from, previous_ts) do
    min_step_ts = previous_ts + minimal_step
    current_ts = System.system_time(:nanosecond)
    new_ts = max(current_ts, min_step_ts)
    {:reply, new_ts, new_ts}
  end
end

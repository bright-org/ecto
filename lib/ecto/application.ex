defmodule Ecto.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    init_uuid_timestamp()

    children = [
      Ecto.Repo.Registry
    ]

    opts = [strategy: :one_for_one, name: Ecto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init_uuid_timestamp do
    if function_exported?(:persistent_term, :put, 2) and
       function_exported?(:atomics, :new, 2) do
      :ok = :persistent_term.put({Ecto.UUID, :nanosecond}, :atomics.new(1, signed: false))
    else
      table = :ets.new(:ecto_uuid_ts, [:set, :public, :named_table])
      :ets.insert(table, {:nanosecond, 0})
      :ok
    end
  end
end

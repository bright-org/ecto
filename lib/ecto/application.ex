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
    # Always use ETS on AtomVM (no atomics/persistent_term). Detect via :atomvm
    # without loading missing OTP modules.
    if function_exported?(:erlang, :system_info, 1) and atomvm_runtime?() do
      init_uuid_timestamp_ets()
    else
      try do
        ref = :atomics.new(1, signed: false)
        :ok = :persistent_term.put({Ecto.UUID, :nanosecond}, ref)
      catch
        _, _ -> init_uuid_timestamp_ets()
      end
    end
  end

  defp atomvm_runtime? do
    case :code.which(:atomvm) do
      :non_existing -> false
      _ -> true
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  defp init_uuid_timestamp_ets do
    table = :ets.new(:ecto_uuid_ts, [:set, :public, :named_table])
    :ets.insert(table, {:nanosecond, 0})
    :ok
  end
end

defmodule Ecto.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children =
      case init_uuid_timestamp() do
        :clock -> [Ecto.UUID.Clock, Ecto.Repo.Registry]
        :atomics -> [Ecto.Repo.Registry]
      end

    opts = [strategy: :one_for_one, name: Ecto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init_uuid_timestamp do
    # Always use the serialized clock on AtomVM (no atomics/persistent_term).
    # Detect via :atomvm without loading missing OTP modules.
    if function_exported?(:erlang, :system_info, 1) and atomvm_runtime?() do
      :clock
    else
      try do
        ref = :atomics.new(1, signed: false)
        :ok = :persistent_term.put({Ecto.UUID, :nanosecond}, ref)
        :atomics
      catch
        _, _ -> :clock
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
end

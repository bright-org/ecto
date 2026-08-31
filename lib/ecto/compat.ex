defmodule Ecto.Compat do
  @moduledoc """
  AtomVM の Integer モジュールには parse/1 が実装されていない
  （AtomVM/libs/exavmlib/lib/Integer.ex を確認済み、floor_div, gcd, mod,
  to_charlist, to_string, extended_gcd のみ）。
  一方 erlang.list_to_integer/1 は AtomVM に存在する
  （estdlib/src/erlang.erl で確認済み）。
  Ecto 内に4箇所あるので共通モジュールにまとめた。
  """

  @doc """
  Portable replacement for `Integer.parse/1` which is unavailable on AtomVM.
  Returns `{integer, rest}` or `:error`.
  """
  def integer_parse(bin) when is_binary(bin) do
    integer_parse(bin, nil, <<>>)
  end

  def integer_parse(other) when not is_binary(other), do: :error

  defp integer_parse(<<c, rest::binary>>, nil, _acc) when c in [?+, ?-] do
    integer_parse(rest, <<c>>, <<>>)
  end

  defp integer_parse(<<c, rest::binary>>, sign, acc) when c >= ?0 and c <= ?9 do
    integer_parse(rest, sign, <<acc::binary, c>>)
  end

  defp integer_parse(rest, sign, acc) when byte_size(acc) > 0 do
    charlist =
      case sign do
        nil -> :erlang.binary_to_list(acc)
        s -> :erlang.binary_to_list(s) ++ :erlang.binary_to_list(acc)
      end

    {:erlang.list_to_integer(charlist), rest}
  end

  defp integer_parse(_rest, _sign, _acc), do: :error
end

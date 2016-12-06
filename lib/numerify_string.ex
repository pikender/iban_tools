defmodule IbanTools.Numerify do
  @moduledoc "Helper with Modulo 97 Numerify IBAN validation"

  defmodule UnexpectedChar do
    @moduledoc "Exception to notify uexpected char"

    defexception message: "Unexpected char"
  end

  @modulo_base 97
  @modulo_value 1

  @doc """
  Performs Modulo 97 operation and return :ok or {:error, _message_code}
  Refer <https://en.wikipedia.org/wiki/International_Bank_Account_Number#Validating_the_IBAN>

      iex(1)> "RO7999991B31007593840000" |> IbanTools.iban_values |> IbanTools.Numerify.check_valid_check_digits
      :ok

      iex(2)> "RO7999991B31007593840001" |> IbanTools.iban_values |> IbanTools.Numerify.check_valid_check_digits
      {:error, :bad_check_digits}
  """
  def check_valid_check_digits(iban_info) do
    if rem(numerify(iban_info), @modulo_base) == @modulo_value do
      :ok
    else
      {:error, :bad_check_digits}
    end
  end

  @doc """
  Returns the IBAN code in numeric form to perform Modulo 97 operation
  Refer <https://en.wikipedia.org/wiki/International_Bank_Account_Number#Validating_the_IBAN>

      iex(3)> "RO7999991B31007593840000" |> IbanTools.iban_values |> IbanTools.Numerify.numerify
      999911131007593840000272479

      iex(4)> "RO7999991B31007593840001" |> IbanTools.iban_values |> IbanTools.Numerify.numerify
      999911131007593840001272479
  """
  def numerify(iban_info) do
    (
      (
        (iban_info.bban |> to_charlist |> numerified([])) ++ 
        (iban_info.country_code |> to_charlist |> numerified([])) ++ 
        (iban_info.check_digits |> to_charlist |> numerified([]))
      )
      |> to_string_from_charlist
      |> String.to_integer
    )
  rescue
    e in UnexpectedChar ->
      raise "#{e.message} in IBAN code '#{IbanTools.pretty_print(iban_info.code)}'"
  end

  defp numerified([], ns), do: ns
  defp numerified([h|t], ns), do: numerified(t, ns ++ [to_char(h)])

  @desc """
    Why not only Kernel.to_string
    as <<32, 57>> fails on match error for String.to_integer
  """
  defp to_string_from_charlist(a) do
    for i <- a, into: "", do: to_string(i)
  end

  defp to_char(chr) when chr in 48..57, do: chr - 48
  defp to_char(chr) when chr in 65..90, do: chr - 55
  defp to_char(chr), do: raise UnexpectedChar, "Unexpected char '#{to_string([chr])}'"
end

defmodule IbanTools do
  @moduledoc "Validates IBAN and inform of errors like invalid iban length, bban format, check digits"

  defp check_min_length(code_len) when code_len > 4, do: :ok
  defp check_min_length(_), do: {:error, :min_length}

  defp check_bad_characters(code) do
    if Regex.match?(~r/^[A-Z0-9]+$/, code) do
      :ok
    else
      {:error, :bad_chars}
    end
  end

  defp check_country_code_length(code_len, ref_code_len) when code_len == ref_code_len, do: :ok
  defp check_country_code_length(_, _), do: {:error, :invalid_code_length}


  defp check_country_bban_format(bban, ref_bban_format) do
    if Regex.match?(ref_bban_format, bban) do
      :ok
    else
      {:error, :invalid_bban_format}
    end
  end

  defp sanitised_iban_values(<<country_code::bytes-size(2)>> <> <<check_digits::bytes-size(2)>> <> rest = sanitised_code, code, code_len) do
    %{
      country_code: country_code, check_digits: check_digits, bban: rest,
      code: sanitised_code, actual_code: code, len: code_len
    }
  end
  defp sanitised_iban_values(sanitised_code, code, code_len) do
    %{
      country_code: "", check_digits: "", bban: "",
      code: sanitised_code, actual_code: code, len: code_len
    }
  end

  @external_resource country_rules_path = Path.join([__DIR__, "rules.txt"])

  for line <- File.stream!(country_rules_path, [], :line) do
    [country_code, code_len, bban_format] = line |> String.split(",") |> Enum.map(&String.strip(&1))

    code_len = String.to_integer(code_len)
    {:ok, bban_pattern} = Regex.compile(bban_format)

    defp country_rules(unquote(country_code)), do: {:ok, %{country_code: unquote(country_code), len: unquote(code_len), bban_pattern: ~r/^#{unquote(bban_pattern.source)}$/}}
  end

  defp country_rules(_), do: {:error, :unknown_country_code}

  @doc """
  Returns IBAN code metadata in map %{} for better use and operations

      iex(5)> "RO7999991B31007593840001" |> IbanTools.iban_values
      %{actual_code: "RO7999991B31007593840001", bban: "99991B31007593840001", check_digits: "79", code: "RO7999991B31007593840001", country_code: "RO", len: 24}
  """
  def iban_values(code) do
    sanitised_code = canonicalize_code(code)
    code_len = String.length(sanitised_code)
    sanitised_iban_values(sanitised_code, code, code_len)
  end

  @doc """
  Validates the IBAN as per length, bban_formats and modulo 97 checks and other sanity checks

      iex(3)>  IbanTools.valid("ES")
      {:error, :min_length, "Code should have atleast 5 characters"}

      iex(4)>  IbanTools.valid("ESA")
      {:error, :min_length, "Code should have atleast 5 characters"}

      iex(5)>  IbanTools.valid("ESAB")
      {:error, :min_length, "Code should have atleast 5 characters"}

      iex(6)> IbanTools.valid("gb99 %BC")
      {:error, :bad_chars, "Only alphanumeric characters allowed"}

      iex(7)> IbanTools.valid("IN9386011117947")
      {:error, :unknown_country_code, "Not a valid SEPA compatible country"}

      iex(8)> IbanTools.valid("ES890182050791020215508")
      {:error, :invalid_code_length, "Violation of Country Code length"}

      iex(9)> IbanTools.valid("ES89AB820507910202155087")
      {:error, :invalid_bban_format, "Violation of Country bban format"}

      iex(10)>  IbanTools.valid("ES8901820507910202155087")
      {:ok, :valid, "Iban code is valid"}
  """
  def check_with(code) do
    with :ok <- check_min_length(String.length(code)),
      iban_info <- iban_values(code),
      {:ok, iban_country_info} <- country_rules(iban_info.country_code),
      :ok <- check_bad_characters(iban_info.code),
      :ok <- check_country_code_length(iban_info.len, iban_country_info.len),
      :ok <- check_country_bban_format(iban_info.bban, iban_country_info.bban_pattern),
      :ok <- IbanTools.Numerify.check_valid_check_digits(iban_info) do
        {:ok, :valid}
    else
      {:error, reason} ->
        {:error, reason}
      _ ->
        {:error, :unexpected_error}
    end
  end

  @messages %{
    valid: "Iban code is valid",
    min_length: "Code should have atleast 5 characters",
    bad_chars: "Only alphanumeric characters allowed",
    bad_check_digits: "Iban fails modulo 97 check, check IBAN again",
    invalid_code_length: "Violation of Country Code length",
    invalid_bban_format: "Violation of Country bban format",
    unknown_country_code: "Not a valid SEPA compatible country",
    unexpected_error: "Unexpected happens, be patient !!",
  }

  @missing_message_key "Please create an issue and report"

  @doc "Wrapper function for `check_with` to help with better error messages along with message codes"
  def valid(code) do
    {status, message_code} = check_with(code)
    {status, message_code, Map.get(@messages, message_code, @missing_message_key)}
  end

  @doc """
  Utility to sanitize IBAN code for better use

      iex(7)> " ro7999991ı31007593840001 " |> IbanTools.canonicalize_code
      "RO7999991I31007593840001"
  """
  def canonicalize_code(code) do
    code
      |> String.trim
      |> String.replace(~r/\s+/, "")
      |> String.upcase
  end

  @doc """
  Utility to print long IBAN codes in groups of 4 digits for better readability

      iex(1)> "RO7999991B31007593840001" |> IbanTools.pretty_print
      "RO79 9999 1B31 0075 9384 0001"
  """
  def pretty_print(code) do
    code
      |> canonicalize_code
      |> String.trim
      |> String.replace(~r/(.{4})/, "\\1 ")
      |> String.trim
  end
end

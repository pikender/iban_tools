defmodule IbanTools do
  def canonicalize_code(code) do
    code
      |> String.trim
      |> String.replace(~r/\s+/, "")
      |> String.upcase
  end

  def pretty_print(code) do
    code
      |> canonicalize_code
      |> String.trim
      |> String.replace(~r/(.{4})/, "\\1 ")
  end

  def country_code(<<country_code::bytes-size(2)>> <> _rest) do
    country_code
  end

  def check_digits(<<_::bytes-size(2)>> <> <<check_digits::bytes-size(2)>> <> _rest) do
    check_digits
  end

  def bban(<<_::bytes-size(2)>> <> <<_::bytes-size(2)>> <> bban) do
    bban
  end

  def check_min_length(code_len) when code_len > 4, do: :ok
  def check_min_length(_), do: {:error, :min_length}

  def check_bad_characters(code) do
    if Regex.match?(~r/^[A-Z0-9]+$/, code) do
      :ok
    else
      {:error, :bad_chars}
    end
  end

  def check_country_code_length(code_len, ref_code_len) when code_len == ref_code_len, do: :ok
  def check_country_code_length(_, _), do: {:error, :invalid_code_length}


  def check_country_bban_format(bban, ref_bban_format) do
    if Regex.match?(ref_bban_format, bban) do
      :ok
    else
      {:error, :invalid_bban_format}
    end
  end

  def iban_values((<<country_code::bytes-size(2)>> <> <<check_digits::bytes-size(2)>> <> rest) = code) do
    %{country_code: country_code, check_digits: check_digits, bban: rest, code: code, len: String.length(code)}
  end

  def country_rules("ES"), do: {:ok, %{country_code: "ES", len: 24, bban_pattern: ~r/^\d{20}$/}}
  def country_rules(_), do: {:error, :unknown_country}

  def check_with(iban_info) do
    with {:ok, iban_country_info} <- country_rules(iban_info.country_code),
      :ok <- check_min_length(iban_info.len),
      :ok <- check_bad_characters(iban_info.code),
      :ok <- check_country_code_length(iban_info.len, iban_country_info.len),
      :ok <- check_country_bban_format(iban_info.bban, iban_country_info.bban_pattern) do
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
    invalid_code_length: "Violation of Country Code length",
    invalid_bban_format: "Violation of Country bban format",
    unknown_country: "Not a valid SEPA compatible country",
    unexpected_error: "Unexpected happens, be patient !!",
  }

  @missing_message_key "Please create an issue and report"

  def valid?(code) do
    iban_info = iban_values(code)
    {status, message_code} = check_with(iban_info)
    {status, message_code, Map.get(@messages, message_code, @missing_message_key)}
  end
end

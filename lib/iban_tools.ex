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

  def iban_values(code) do
    sanitised_code = canonicalize_code(code)
    code_len = String.length(sanitised_code)
    sanitised_iban_values(sanitised_code, code, code_len)
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

    def country_rules(unquote(country_code)), do: {:ok, %{country_code: unquote(country_code), len: unquote(code_len), bban_pattern: ~r/^#{unquote(bban_pattern.source)}$/}}
  end

  def country_rules(_), do: {:error, :unknown_country_code}

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

  def valid(code) do
    {status, message_code} = check_with(code)
    {status, message_code, Map.get(@messages, message_code, @missing_message_key)}
  end
end

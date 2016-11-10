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

  def country_code(<<country_code::bytes-size(2)>> <> rest) do
    country_code
  end

  def check_digits(<<_::bytes-size(2)>> <> <<check_digits::bytes-size(2)>> <> rest) do
    check_digits
  end

  def bban(<<_::bytes-size(2)>> <> <<_::bytes-size(2)>> <> bban) do
    bban
  end

  # TODO:
  ## Check `with` syntax
  ## Add more country clauses from YAML write
  ## Better Errors Mgmt
  def basic_check(code) do
    case String.length(code) < 5 do
      true -> "Check Failed"
      _ -> check_bad_chars(code)
    end
  end

  def check_bad_chars(code) do
    case Regex.match?(~r/^[A-Z0-9]+$/, code) do
      false -> "Invalid Chars"
      _ -> country_rules_check(code)
    end
  end

  def country_rules_check(("ES" <> <<dg::bytes-size(2)>> <> rest) = code) do
    if String.length(code) == 24 do
      if Regex.match?(~r/^\d{8}[A-Z0-9]{12}$/, rest) do
        "Valid"
      else
        "Format mismatch"
      end
    else
      "Length Mismatch"
    end
  end
  def country_rules_check(_), do: "Unknown Country"
end

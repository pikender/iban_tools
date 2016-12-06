# IbanTools [![Build Status](https://travis-ci.org/pikender/iban_tools.svg?branch=master)](https://travis-ci.org/pikender/iban_tools)

Iban validation and helpers
Refer <https://en.wikipedia.org/wiki/International_Bank_Account_Number> for more details

## Installation

  1. Add `iban_tools` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:iban_tools, "~> 0.1.0"}]
    end
    ```

## Usage

  1. Get Iban related info in map

      ```elixir
      iex(2)> IbanTools.iban_values("ES12345")
      %{actual_code: "ES12345", bban: "345", check_digits: "12", code: "ES12345", country_code: "ES", len: 7}
      ```

  2. Validate Iban and get error info as per violation

      ```elixir
      iex(10)>  IbanTools.valid("ES8901820507910202155087")
      {:ok, :valid, "Iban code is valid"}
      ```

  3. Get numerified Iban value as needed for check digit validation (modulo 97)

      ```elixir
      iex(4)> "GB82 WEST 1234 5698 7654 32" |> IbanTools.iban_values |> IbanTools.Numerify.numerify
      3214282912345698765432161182
      ```

  4. Validate Modulo 97 check passes or not

      ```elixir
      iex(1)> "RO7999991B31007593840000" |> IbanTools.iban_values |> IbanTools.Numerify.check_valid_check_digits
      :ok
      ```

  5. Get sanitised IBAN code

      ```elixir
      iex(7)> " ro7999991ı31007593840001 " |> IbanTools.canonicalize_code
      "RO7999991I31007593840001"
      ```

  6. Pretty print IBAN code for better human readability

      ```elixir
      iex(1)> "RO7999991B31007593840001" |> IbanTools.pretty_print
      "RO79 9999 1B31 0075 9384 0001"
      ```

### Supported Error/Message codes

  ```elixir
  iex(3)>  IbanTools.valid("ES")
  {:error, :min_length, "Code should have atleast 5 characters"}

  iex(4)>  IbanTools.valid("ESA")
  {:error, :min_length, "Code should have atleast 5 characters"}

  iex(5)>  IbanTools.valid("ESAB")
  {:error, :min_length, "Code should have atleast 5 characters"}
  ```

  ```elixir
  iex(5)> IbanTools.valid("gb99 %BC")
  {:error, :bad_chars, "Only alphanumeric characters allowed"}
  ```

  ```elixir
  iex(6)> IbanTools.valid("IN9386011117947")
  {:error, :unknown_country_code, "Not a valid SEPA compatible country"}
  ```

  ```elixir
  iex(7)> IbanTools.valid("ES890182050791020215508")
  {:error, :invalid_code_length, "Violation of Country Code length"}
  ```

  ```elixir
  iex(8)> IbanTools.valid("ES89AB820507910202155087")
  {:error, :invalid_bban_format, "Violation of Country bban format"}
  ```

  ```elixir
  iex(2)> "RO7999991B31007593840001" |> IbanTools.iban_values |> IbanTools.Numerify.check_valid_check_digits
  {:error, :bad_check_digits}
  ```

defmodule IbanToolsTest do
  use ExUnit.Case
  doctest IbanTools

  def valid(code) do
    {status, message_code, message} = IbanTools.valid(code)
    %{status: status, message_code: message_code, message: message}
  end

  def status(code) do
    Map.get(valid(code), :status)
  end

  test "should validate IBAN code" do
    assert {:ok, _, _} = IbanTools.valid("ES8901820507910202155087")
	end

  test "should reject IBAN code wtesth invalid characters" do
    assert {:error, :bad_chars, _} = IbanTools.valid("gb99 %BC")
  end

  test "should reject IBAN code from unknown country" do
    assert {:error, :unknown_country_code, _} = IbanTools.valid("IN9386011117947")
  end

  test "should reject IBAN code that does not match the length for the respective country" do
    assert {:error, :invalid_code_length, _} = IbanTools.valid("ES890182050791020215508")
  end

  test "should reject IBAN code that does not match the pattern for the selected country" do
    assert {:error, :invalid_bban_format, _} = IbanTools.valid("ES89AB820507910202155087")
  end

  test "should reject IBAN code with invalid check digits" do
    assert :ok == ("RO7999991B31007593840000" |> IbanTools.iban_values |> IbanTools.Numerify.check_valid_check_digits)
  end

  test "should numerify IBAN code" do
    assert ("GB82 WEST 1234 5698 7654 32" |> IbanTools.iban_values |> IbanTools.Numerify.numerify) == 3214282912345698765432161182
  end

  test "should canonicalize IBAN code" do
    assert IbanTools.canonicalize_code("  gb82 WeSt 1234 5698 7654 32") == "GB82WEST12345698765432"
  end

  test "should pretty-print IBAN code" do
    assert IbanTools.pretty_print(" GB82W EST12 34 5698 765432  ") == "GB82 WEST 1234 5698 7654 32"
  end

  test "should extract ISO country code" do
    assert IbanTools.iban_values("ES8901820507910202155087").country_code == "ES"
  end

  test "should extract check digits" do
    assert IbanTools.iban_values("ES8901820507910202155087").check_digits == "89"
  end

  test "should extract BBAN (Basic Bank Account Number)" do
    assert IbanTools.iban_values("ES8901820507910202155087").bban == "01820507910202155087"
  end

  test "should fail known pattern violations" do
    assert {:error, :invalid_bban_format, _} = IbanTools.valid("RO7999991B31007593840000")
  end

  Enum.map(
  [
    "AD1200012030200359100100",
    "AE070331234567890123456",
    "AL47212110090000000235698741",
    "AT611904300234573201",
    "AZ21NABZ00000000137010001944",
    "BA391290079401028494",
    "BE68539007547034",
    "BG80BNBG96611020345678",
    "BH67BMAG00001299123456",
    "BR7724891749412660603618210F3",
    "CH9300762011623852957",
    "CY17002001280000001200527600",
    "CZ6508000000192000145399",
    "DE89370400440532013000",
    "DK5000400440116243",
    "DO28BAGR00000001212453611324",
    "EE382200221020145685",
    "ES9121000418450200051332",
    "FI2112345600000785",
    "FO7630004440960235",
    "FR1420041010050500013M02606",
    "GB29NWBK60161331926819",
    "GE29NB0000000101904917",
    "GI75NWBK000000007099453",
    "GL4330003330229543",
    "GR1601101250000000012300695",
    "HR1210010051863000160",
    "HU42117730161111101800000000",
    "IE29AIBK93115212345678",
    "IL620108000000099999999",
    "IS140159260076545510730339",
    "IT60X0542811101000000123456",
    "KW81CBKU0000000000001234560101",
    "KZ86125KZT5004100100",
    "LB62099900000001001901229114",
    "LI21088100002324013AA",
    "LT121000011101001000",
    "LU280019400644750000",
    "LV80BANK0000435195001",
    "MC1112739000700011111000h79",
    "MD24AG000225100013104168",
    "ME25505000012345678951",
    "MK07300000000042425",
    "MR1300020001010000123456753",
    "MT84MALT011000012345MTLCAST001S",
    "MU17BOMM0101101030300200000MUR",
    "NL91ABNA0417164300",
    "NO9386011117947",
    "PK36SCBL0000001123456702",
    "PL27114020040000300201355387",
    "PT50000201231234567890154",
    "QA58DOHB00001234567890ABCDEFG",
    "RO49AAAA1B31007593840000",
    "RS35260005601001611379",
    "SA0380000000608010167519",
    "SE3550000000054910000003",
    "SI56191000000123438",
    "SK3112000000198742637541",
    "SM86U0322509800000000270100",
    "TN5914207207100707129648",
    "TR330006100519786457841326",
  ],
  fn(code) ->
    test "should be valid #{code}" do
      assert {:ok, _, _} = IbanTools.valid(unquote(code))
    end
  end)
end

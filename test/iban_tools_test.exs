defmodule IbanToolsTest do
  use ExUnit.Case
  doctest IbanTools

	test "should validate IBAN code" do
    assert basic_check("ES8901820507910202155087") == "Valid"
	end

	test "should reject IBAN code wtesth invalid characters" do
    assert basic_check("gb99 %BC") == "Invalid Chars"
  end

	test "should reject IBAN code from unknown country" do
    assert basic_check("NO9386011117947") == "Unknown Country"
  end

	test "should reject IBAN code that does not match the length for the respective country" do
    assert basic_check("ES890182050791020215508") == "Length Mismatch"
  end

	test "should reject IBAN code that does not match the pattern for the selected country" do
    assert basic_check("ES89AB820507910202155087") == "Format mismatch"
  end

	test "should reject IBAN code wtesth invalid check digtests"

	test "should numerify IBAN code"

	test "should canonicalize IBAN code" do
    assert canonicalize_code("  gb82 WeSt 1234 5698 7654 32") == "GB82WEST12345698765432"
  end

	test "should pretty-print IBAN code" do
    assert pretty_print(" GB82W EST12 34 5698 765432  ") == "GB82 WEST 1234 5698 7654 32"
  end

	test "should extract ISO country code" do
    assert country_code("ES8901820507910202155087") == "ES"
  end

	test "should extract check digits" do
    assert check_digits("ES8901820507910202155087") == "89"
  end

	test "should extract BBAN (Basic Bank Account Number)" do
    assert bban("ES8901820507910202155087") == "01820507910202155087"
  end

	test "should be valid" do
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
			"CR0515202001026284066",
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
			"GT82TRAJ01020000001210029690",
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
			"PS92PALS000000000400123456702",
			"PT50000201231234567890154",
			"QA58DOHB00001234567890ABCDEFG",
			"RO49AAAA1B31007593840000",
			"RS35260005601001611379",
			"SA0380000000608010167519",
			"SE3550000000054910000003",
			"SI56191000000123438",
			"SK3112000000198742637541",
			"SM86U0322509800000000270100",
			"TL380080012345678910157",
			"TN5914207207100707129648",
			"TR330006100519786457841326",
			"VG96VPVG0000012345678901",
			"XK051212012345678906"
		],
    fn(code) ->
      assert basic_check(code) == "Valid"
    end)
  end

	test "should fail known pattern violations" do
    assert basic_check("RO7999991B31007593840000") == "Valid"
  end

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

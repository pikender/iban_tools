defmodule IbanTools.Mixfile do
  use Mix.Project

  def project do
    [app: :iban_tools,
     version: "0.1.0",
     description: description(),
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end
  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev},
    {:earmark, "~> 1.0", only: :dev}]
  end

  defp package do
    [
      name: :iban_tools,
      files: ["config", "lib", "test", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Pikender Sharma"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/pikender/iban_tools",
      "Docs" => "https://github.com/pikender/iban_tools/blob/master/README.md"}]
  end

  defp description do
    "Iban validation and helpers https://en.wikipedia.org/wiki/International_Bank_Account_Number"
  end
end

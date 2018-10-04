defmodule UeberauthEcwid.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/nsweeting/ueberauth_ecwid"

  def project do
    [
      app: :ueberauth_ecwid,
      name: "Ueberauth Ecwid Strategy",
      version: @version,
      package: package(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      source_url: @url,
      homepage_url: @url,
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Nicholas Sweeting"],
      licenses: ["MIT"],
      links: %{"GitHub": @url}
    ]
  end

  defp description do
    """
      An Ueberauth strategy for authenticating your application with Ecwid.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 0.9.0"},
      {:ueberauth, "~> 0.4.0"},
      {:ex_doc, "~> 0.14.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end
end

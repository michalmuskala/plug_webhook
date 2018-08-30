defmodule PlugWebhook.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :plug_webhook,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.4"},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description do
    """
    Simple tool for building plugs that handle wehbooks and verify signature.
    """
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/michalmuskala/plug_webhook"}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/plug_webhook",
      source_url: "https://github.com/michalmuskala/plug_webhook",
      main: "PlugWebhook"
    ]
  end
end

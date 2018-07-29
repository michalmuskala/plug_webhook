defmodule PlugWebhook.MixProject do
  use Mix.Project

  def project do
    [
      app: :plug_webhook,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.4"}
    ]
  end
end

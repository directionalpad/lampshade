defmodule Lampshade.MixProject do
  use Mix.Project

  def project do
    [
      app: :lampshade,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Lampshade, []},
      extra_applications: [:nerves_ssdp_client, :httpoison, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:huex, "~> 0.7"},
      {:nerves_ssdp_client, "~> 0.1.0"}
    ]
  end
end

defmodule MessageApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :message_app,
      version: "1.0.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "test.coveralls": :test,
        "ecto.setup": :test,
        "ecto.reset": :test
      ]
    ]
  end

  def application do
    [
      mod: {MessageApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix Core
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_view, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:finch, "~> 0.13"},

      # Security & Rate Limiting
      {:cors_plug, "~> 3.0"},
      {:ex_rated, "~> 2.1"},

      # Telemetry
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # Dev only
      {:phoenix_live_reload, "~> 1.4", only: :dev},

      # Test only
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:excoveralls, "~> 0.18", only: :test},

      # Code quality
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

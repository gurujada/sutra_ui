import Config

# The esbuild Hex package builds assets/js into priv/static (maintainers only: `mix assets.build`).
if config_env() == :dev do
  config :esbuild,
    version: "0.25.4",
    sutra_ui: [cd: Path.expand("..", __DIR__)]
end

# Tests convert times to named zones; apps configure their own time zone database.
if config_env() == :test do
  config :elixir, :time_zone_database, Tz.TimeZoneDatabase

  config :logger, level: :warning

  # An endpoint and router for LiveView tests (test/support).
  config :sutra_ui, SutraUI.TabsLive.Endpoint,
    secret_key_base: String.duplicate("a", 64),
    live_view: [signing_salt: "tabs-live-salt"],
    server: false
end

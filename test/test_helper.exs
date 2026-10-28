{:ok, _} = Supervisor.start_link([SutraUI.TabsLive.Endpoint], strategy: :one_for_one)

ExUnit.start()

# Configure ExUnit
ExUnit.configure(exclude: [:skip], formatters: [ExUnit.CLIFormatter])

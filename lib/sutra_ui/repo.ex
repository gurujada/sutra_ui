defmodule SutraUi.Repo do
  use Ecto.Repo,
    otp_app: :sutra_ui,
    adapter: Ecto.Adapters.Postgres
end

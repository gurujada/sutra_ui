defmodule SutraUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SutraUiWeb.Telemetry,
      SutraUi.Repo,
      {DNSCluster, query: Application.get_env(:sutra_ui, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SutraUi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SutraUi.Finch},
      # Start a worker by calling: SutraUi.Worker.start_link(arg)
      # {SutraUi.Worker, arg},
      # Start to serve requests, typically the last entry
      SutraUiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SutraUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SutraUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

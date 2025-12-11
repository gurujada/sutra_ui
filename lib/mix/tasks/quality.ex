defmodule Mix.Tasks.Quality do
  @shortdoc "Run all quality checks (format, compile, test)"
  @moduledoc """
  Runs all quality gate checks for Sutra UI.

  ## Usage

      mix quality

  ## Checks

  Runs the following checks in order (fail-fast):

  1. `mix format --check-formatted` - Code formatting
  2. `mix compile --warnings-as-errors` - Compilation without warnings
  3. `mix test` - Test suite

  If any check fails, the task exits with a non-zero status code
  and subsequent checks are not run.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Running quality checks...\n")

    checks = [
      {"Checking formatting...", "format", ["--check-formatted"]},
      {"Compiling with warnings as errors...", "compile", ["--warnings-as-errors"]},
      {"Running tests...", "test", []}
    ]

    Enum.reduce_while(checks, :ok, fn {message, task, args}, _acc ->
      Mix.shell().info(message)

      case run_task(task, args) do
        :ok ->
          Mix.shell().info("✓ Passed\n")
          {:cont, :ok}

        {:error, exit_code} ->
          Mix.shell().error("✗ Failed (exit code: #{exit_code})\n")
          System.halt(exit_code)
          {:halt, {:error, exit_code}}
      end
    end)

    Mix.shell().info("All quality checks passed!")
  end

  defp run_task(task, args) do
    # Use System.cmd to run mix tasks and capture exit code
    {_output, exit_code} =
      System.cmd("mix", [task | args], into: IO.stream(:stdio, :line), stderr_to_stdout: true)

    if exit_code == 0, do: :ok, else: {:error, exit_code}
  end
end

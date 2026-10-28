defmodule SutraUI.CSPTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Avatar
  alias SutraUI.Tooltip

  @lib Path.wildcard("lib/sutra_ui/*.ex")

  test "every runtime hook script accepts a CSP nonce" do
    for file <- @lib,
        line <- File.stream!(file) |> Enum.to_list(),
        String.contains?(line, "ColocatedHook}") and String.contains?(line, "runtime") do
      assert line =~ "nonce={@nonce}", "#{file}: #{String.trim(line)}"
    end
  end

  test "no component renders an inline event handler attribute by default" do
    for file <- @lib, line <- File.stream!(file) |> Enum.to_list() do
      refute line =~ ~r/\s+on(error|click|load|change|submit)="/ and not (line =~ "onerror={")
    end
  end

  test "a runtime hook script carries the nonce passed to its component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Tooltip.tooltip id="t1" tooltip="Hi" nonce="n0nce">Hover</Tooltip.tooltip>
      """)

    assert html =~ ~r/<script[^>]*nonce="n0nce"/
    assert html =~ "data-phx-runtime-hook"
  end

  test "avatar with an id uses a nonce-able hook instead of an onerror handler" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar id="av1" src="/a.png" alt="A" nonce="n0nce" />
      """)

    refute html =~ "onerror"
    assert html =~ ~s(phx-hook=".Avatar")
    assert html =~ ~r/<script[^>]*nonce="n0nce"/
  end

  test "avatar without an id keeps the legacy onerror fallback" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar src="/a.png" alt="A" />
      """)

    assert html =~ "onerror="
    refute html =~ "<script"
  end
end

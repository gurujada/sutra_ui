defmodule SutraUI.Toast.Test do
  @moduledoc """
  Helpers for testing toasts in `Phoenix.LiveViewTest`, without a browser.

      import SutraUI.Toast.Test

      {:ok, view, _html} = live(conn, ~p"/courses")
      view |> element("#publish") |> render_click()
      assert_toast(view, :success, "Course published")
      refute_toast(view, :error)

  A toast that is closing (dismissed, waiting for its exit animation) no longer counts.
  """

  import Phoenix.LiveViewTest, only: [has_element?: 2, has_element?: 3]

  @doc """
  Asserts that the page holds a toast of `kind` whose text contains `text`.
  """
  def assert_toast(view, kind, text) when is_binary(text) do
    unless has_element?(view, selector(kind), text) do
      fail("expected a #{kind} toast containing #{inspect(text)}, found none")
    end

    true
  end

  @doc """
  Asserts that the page holds no toast of `kind` (containing `text` when given).
  """
  def refute_toast(view, kind, text \\ nil) do
    found? =
      if text,
        do: has_element?(view, selector(kind), text),
        else: has_element?(view, selector(kind))

    if found? do
      fail("expected no #{kind} toast#{text && " containing #{inspect(text)}"}, found one")
    end

    true
  end

  defp selector(kind) do
    kind = SutraUI.Toast.check_kind!(kind)
    "[data-toast][data-kind=\"#{kind}\"]:not([data-state=\"closing\"])"
  end

  # ExUnit is not a dependency of the library: look the exception up at run time.
  defp fail(message) do
    exception = Module.concat(ExUnit, AssertionError)
    raise exception, message: message
  end
end

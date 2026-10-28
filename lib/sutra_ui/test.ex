defmodule SutraUI.Test do
  @moduledoc """
  The one import for testing Sutra UI in `Phoenix.LiveViewTest`, without a browser.

      import SutraUI.Test

      test "publishing", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/courses/new")

        pick(view, "course[opens]", ~D[2027-03-15], form: "#course-form")
        view |> element("#publish") |> render_click()
        assert_toast(view, :success, "Course published")

        confirm(view, "#retire-confirm")
      end

  | Function | Does | Details |
  |----------|------|---------|
  | `pick/4`, `params/3` | Picks a date, range, time or datetime the way the picker posts it | `SutraUI.Test.Dates` |
  | `assert_toast/3`, `refute_toast/3` | Asserts a toast of a kind is (not) on the page | `SutraUI.Toast.Test` |
  | `confirm/2`, `confirm/3` | Confirms a `confirm_dialog` or a `data-confirm` element | `SutraUI.Confirm.Test` |

  Each function is defined in the module named in the table, which you can also import on
  its own.
  """

  alias SutraUI.Confirm
  alias SutraUI.Test.Dates
  alias SutraUI.Toast

  @doc "See `SutraUI.Test.Dates.pick/4`."
  defdelegate pick(view, name, value, opts), to: Dates

  @doc "See `SutraUI.Test.Dates.pick/4`."
  def pick(view, name, value), do: Dates.pick(view, name, value, [])

  @doc "See `SutraUI.Test.Dates.params/3`."
  defdelegate params(name, value, opts), to: Dates

  @doc "See `SutraUI.Test.Dates.params/3`."
  def params(name, value), do: Dates.params(name, value, [])

  @doc "See `SutraUI.Toast.Test.assert_toast/3`."
  defdelegate assert_toast(view, kind, text), to: Toast.Test

  @doc "See `SutraUI.Toast.Test.refute_toast/3`."
  defdelegate refute_toast(view, kind, text), to: Toast.Test

  @doc "See `SutraUI.Toast.Test.refute_toast/3`."
  def refute_toast(view, kind), do: Toast.Test.refute_toast(view, kind, nil)

  @doc "See `SutraUI.Confirm.Test.confirm/3`."
  defdelegate confirm(view, selector, fields), to: Confirm.Test

  @doc "See `SutraUI.Confirm.Test.confirm/3`."
  def confirm(view, selector), do: Confirm.Test.confirm(view, selector, %{})
end

defmodule SutraUI.Confirm.Test do
  @moduledoc """
  Confirm in `Phoenix.LiveViewTest`.

  `data-confirm` is a browser behaviour: in a LiveView test a click goes straight through, so
  the usual `render_click/1` already "confirms" it. The `confirm_dialog` is a form, whose verb
  submits it.

      import SutraUI.Confirm.Test

      confirm(view, "#retire-confirm")      # the dialog with that id: runs its verb
      confirm(view, "#archive-button")      # an element: clicks it (data-confirm is ignored)
  """

  import Phoenix.LiveViewTest,
    only: [element: 2, form: 3, has_element?: 2, render_click: 1, render_submit: 1]

  @doc """
  Confirms: submits the `confirm_dialog` the selector names (with `values` extra fields in
  `fields`), or clicks the element when it is not a dialog.
  """
  def confirm(view, selector, fields \\ %{}) do
    form_selector = selector <> "-form"

    if has_element?(view, form_selector) do
      view |> form(form_selector, fields) |> render_submit()
    else
      view |> element(selector) |> render_click()
    end
  end
end

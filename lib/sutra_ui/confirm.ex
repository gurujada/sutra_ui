defmodule SutraUI.Confirm do
  @moduledoc """
  Confirmations: one question, a distinct verb, and nothing drawn by the browser.

  Confirm only what cannot be undone. Anything reversible acts at once and offers Undo in a
  toast (`SutraUI.Toast`). When you do ask, the dialog names the action, says in one line
  what happens, and offers "Keep it" next to a verb that says what it does ("Delete",
  "Retire"), never "OK".

  Both components are built on `SutraUI.Dialog`, a fixed-position `div`, never a native
  `<dialog>` and never `window.confirm()`: they stay visible when a browser tab is shared in
  Google Meet or Zoom, work inside cross-origin iframes and in-app browsers, and cannot be
  silenced with "don't show more dialogs".

  | Component | Use |
  |-----------|-----|
  | `confirm_dialog/1` | A question you write in HEEx, with an `event` the verb pushes and optional extra fields (a reason) |
  | `confirm_host/1` | One per layout: makes every `data-confirm` on the page use the same styled dialog |

  ## A dialog you write

      <.button phx-click={SutraUI.open_confirm("retire-confirm")}>Retire</.button>

      <.confirm_dialog
        id="retire-confirm"
        title="Retire this course?"
        consequence="Learners keep their certificates; nobody can start it again."
        confirm="Retire"
        event="retire"
        values={%{"id" => @course.id}}
      />

  `values` arrive as event params (strings, like form fields); any key works, including `id`. Put extra fields in the
  inner block (they are inside the form, so the verb submits them too):

      <.confirm_dialog id="remove" title="Remove Asha?" consequence="She loses access today."
                       confirm="Remove" event="remove_member">
        <.input name="reason" label="Reason" value="" />
      </.confirm_dialog>

  To have the host (the LiveView) hold the open state instead, pass `show` and `on_cancel`;
  Keep, Esc and the backdrop then push `on_cancel`, and your handler closes it.

  ## `data-confirm` without code changes

  Add one host to the layout, once:

      <.confirm_host />

  Every element with `data-confirm` then opens it instead of the browser's box:

      <.link href={~p"/courses/\#{@course}"} method="delete" data-confirm="This deletes the course."
             data-confirm-title="Delete this course?" data-confirm-verb="Delete">Delete</.link>
      <button phx-click="archive" data-confirm="Archive 12 lessons?" data-confirm-tone="primary">Archive</button>
      <.form for={@form} phx-submit="send" data-confirm="Send to all 80 learners?">...</.form>

  | Attribute | Meaning |
  |-----------|---------|
  | `data-confirm` | The message (the consequence line) |
  | `data-confirm-title` | The question; default "Are you sure?" |
  | `data-confirm-verb` | The verb button; default "Confirm" |
  | `data-confirm-tone` | `danger` (default; focus starts on Keep) or `primary` |

  The click is caught in the capture phase on `window`, before LiveView and phoenix_html see
  it, so a `phx-click` button, a `data-method` link and a submit button behave as before once
  the verb is pressed: the original click is replayed (marked, so it passes through). Keep,
  Esc and the backdrop do nothing and return focus to the element.

  The host's hook installs the catcher when it mounts. To catch clicks that happen before
  the LiveView connects, also call it from `app.js`:

      import {installConfirm} from "sutra_ui/confirm"
      installConfirm()

  Without a host on the page, `data-confirm` keeps phoenix_html's own prompt.

  In `Phoenix.LiveViewTest`, `data-confirm` is ignored (clicks go straight through), so
  existing tests keep working. `SutraUI.Confirm.Test.confirm/2` clicks an element and then
  runs the verb of the `confirm_dialog` it opens.

  ## Accessibility

  - `role="alertdialog"` with `aria-modal`, labelled by the question and described by the
    consequence
  - The page behind is `inert`: nothing behind can be clicked, focused or read by a screen reader
  - Focus is trapped inside; it starts on Keep for a danger action; Esc means Keep; focus
    returns to the element that opened it
  - The tone is a word and a different verb, never colour alone
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  alias SutraUI.Button
  alias SutraUI.Dialog

  @doc """
  A confirmation dialog you write in HEEx.

  Open it from the browser with `SutraUI.open_confirm/1` (or `open_confirm/2` to chain), or
  control it from the LiveView with `show` and `on_cancel`.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, required: true, doc: "The question, naming the action")
  attr(:consequence, :string, required: true, doc: "What happens, in one line")
  attr(:confirm, :string, required: true, doc: "The verb on the button, such as \"Retire\"")
  attr(:keep, :string, default: "Keep it", doc: "The label of the button that changes nothing")
  attr(:event, :string, required: true, doc: "The event the verb pushes")
  attr(:values, :map, default: %{}, doc: "Sent with the event; they arrive as string params")
  attr(:tone, :atom, values: [:danger, :primary], default: :danger)
  attr(:target, :any, default: nil, doc: "`phx-target` of the pushed events")
  attr(:show, :boolean, default: false)
  attr(:on_cancel, :string, default: nil, doc: "Host event pushed by Keep, Esc and the backdrop")
  attr(:rest, :global)

  slot(:inner_block, doc: "Extra fields, such as a reason; they submit with the verb")

  def confirm_dialog(assigns) do
    close =
      if assigns.on_cancel,
        do: assigns.id |> close_confirm() |> JS.push(assigns.on_cancel, target: assigns.target),
        else: close_confirm(assigns.id)

    # `values` ride on the push, not on hidden inputs: LiveView warns about (and mishandles) an
    # input named `id`, the usual key. They arrive as strings, as form fields do.
    push =
      JS.push(assigns.event,
        target: assigns.target,
        value: Map.new(assigns.values, fn {k, v} -> {to_string(k), to_string(v)} end)
      )

    submit = if assigns.on_cancel, do: push, else: close_confirm(push, assigns.id)

    assigns = assign(assigns, close: close, submit: submit)

    ~H"""
    <Dialog.dialog
      id={@id}
      show={@show}
      on_cancel={@close}
      alert
      inert_page
      initial_focus={@tone == :danger && "[data-confirm-keep]"}
      data-tone={@tone}
      {@rest}
    >
      <:title>
        <span class="flex items-start gap-2 pr-8">
          <.alert_icon :if={@tone == :danger} />{@title}
        </span>
      </:title>
      <:description>{@consequence}</:description>
      <.form for={%{}} id={"#{@id}-form"} phx-submit={@submit} class="space-y-4">
        {render_slot(@inner_block)}
        <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <Button.button type="button" variant="ghost" data-confirm-keep phx-click={@close}>
            {@keep}
          </Button.button>
          <Button.button
            type="submit"
            variant={if @tone == :danger, do: "destructive", else: "primary"}
            data-confirm-ok
            data-tone={@tone}
            phx-disable-with="Working…"
          >
            {@confirm}
          </Button.button>
        </div>
      </.form>
    </Dialog.dialog>
    """
  end

  @doc """
  The one confirm dialog behind every `data-confirm` on the page. Render it once in the
  layout.

  The words around the message are attributes, so an app can translate them.
  """
  attr(:id, :string, default: "sutra-confirm")

  attr(:title, :string,
    default: "Are you sure?",
    doc: "Used when an element has no `data-confirm-title`"
  )

  attr(:confirm, :string,
    default: "Confirm",
    doc: "Used when an element has no `data-confirm-verb`"
  )

  attr(:keep, :string, default: "Keep it")

  def confirm_host(assigns) do
    assigns = assign(assigns, :dialog_id, "#{assigns.id}-dialog")

    ~H"""
    <div id={@id} phx-hook=".ConfirmHost" data-sutra-confirm-host data-default-title={@title}>
      <Dialog.dialog id={@dialog_id} alert inert_page initial_focus="[data-confirm-keep]">
        <:title>
          <span class="flex items-start gap-2">
            <.alert_icon data-confirm-icon /><span data-confirm-title>{@title}</span>
          </span>
        </:title>
        <:description><span data-confirm-message></span></:description>
        <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <Button.button
            type="button"
            variant="ghost"
            data-confirm-keep
            data-confirm-cancel
            phx-click={Dialog.hide_dialog(@dialog_id)}
          >
            {@keep}
          </Button.button>
          <Button.button
            type="button"
            variant="destructive"
            data-confirm-ok
            data-tone="danger"
            data-default-verb={@confirm}
          >
            {@confirm}
          </Button.button>
          <Button.button
            type="button"
            variant="primary"
            data-confirm-ok
            data-tone="primary"
            data-default-verb={@confirm}
            hidden
          >
            {@confirm}
          </Button.button>
        </div>
      </Dialog.dialog>
    </div>

    <script :type={ColocatedHook} name=".ConfirmHost">
      import {ConfirmHost} from "sutra_ui/confirm"
      export default ConfirmHost
    </script>
    """
  end

  # The triangle-alert glyph a danger confirmation carries with its title, so the tone is
  # never colour alone (the command palette's confirm step shows the same one).
  attr(:rest, :global)

  defp alert_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="mt-px size-[1.125rem] shrink-0 text-destructive"
      aria-hidden="true"
      {@rest}
    >
      <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" />
    </svg>
    """
  end

  @doc """
  Opens a `confirm_dialog` (a sticky class, so a server patch keeps it open).

      <.button phx-click={SutraUI.open_confirm("retire-confirm")}>Retire</.button>
  """
  def open_confirm(js \\ %JS{}, id) when is_binary(id) do
    js |> JS.add_class("is-open", to: "##{id}") |> Dialog.show_dialog(id)
  end

  @doc "Closes a `confirm_dialog` opened with `open_confirm/1`."
  def close_confirm(js \\ %JS{}, id) when is_binary(id) do
    js |> JS.remove_class("is-open", to: "##{id}") |> Dialog.hide_dialog(id)
  end
end

# Sutra UI Recipes

Use these as starting shapes. Always inspect the component module for exact
attrs before implementing.

## Popover + Calendar

Use this when a page needs a custom visible calendar experience. Keep selected
date and displayed month in the parent LiveView.

```heex
<.popover id="due-date-popover" side="bottom" align="start">
  <:trigger>
    <.button type="button" variant="outline">
      {@selected_date || "Pick a date"}
    </.button>
  </:trigger>

  <.calendar
    selected={@selected_date}
    year={@calendar_year}
    month={@calendar_month}
    select_event="select_due_date"
    nav_event="nav_due_date_month"
  />
</.popover>
```

```elixir
def handle_event("select_due_date", %{"date" => date}, socket) do
  selected = Date.from_iso8601!(date)

  {:noreply,
   assign(socket,
     selected_date: selected,
     calendar_year: selected.year,
     calendar_month: selected.month
   )}
end

def handle_event("nav_due_date_month", %{"year" => year, "month" => month}, socket) do
  {:noreply,
   assign(socket,
     calendar_year: String.to_integer(year),
     calendar_month: String.to_integer(month)
   )}
end
```

Use native `<.input type="date">` instead when a browser date input is enough.

## Multi-Step Phoenix Form

Use `stepper_wizard/1` as the shell. The parent LiveView owns the form,
validation, current step, and step transitions.

```heex
<.form for={@form} class="form" phx-change="validate" phx-submit="continue">
  <.stepper_wizard id="checkout" current={@step} errors={@step_errors}>
    <:step id="shipping" label="Shipping">
      <.input field={@form[:name]} label="Name" />
      <.input field={@form[:address]} label="Address" />
    </:step>

    <:step id="payment" label="Payment">
      <.input field={@form[:card_number]} label="Card number" />
    </:step>

    <:step id="confirm" label="Confirm">
      <.card>
        <:content>Review your order.</:content>
      </.card>
    </:step>

    <:actions>
      <.button type="button" variant="outline" phx-click="previous_step">Back</.button>
      <.button type="submit">Continue</.button>
    </:actions>
  </.stepper_wizard>
</.form>
```

Validate the whole changeset on `phx-change`; show per-field errors through
`input/1`. Compute `@step_errors` from the active step's required fields when
the user submits or moves between steps.

## Activity + Response Agent Surface

Use `activity/1` for visible progress and `response/1` for output. Stream rows
by updating the list in the parent LiveView; stream response text by updating
the `value`.

```heex
<.activity compact>
  <:item :for={step <- @activity_steps} id={step.id} status={step.status}>
    {step.label}
  </:item>
</.activity>

<.response
  id="assistant-response"
  value={@answer}
  format="markdown"
  streaming={@streaming}
/>
```

Do not show private reasoning. Activity rows should be safe, user-facing work
summaries.

## Timeline Activity Feed

Use timeline for chronological app events. Put avatars, badges, links, and
actions inside each `:item`.

```heex
<.timeline>
  <:item time="12 min ago">
    <div class="flex items-start gap-3">
      <.avatar initials="AM" />
      <div>
        <p><strong>Alex Morgan</strong> created a project</p>
        <.badge variant="secondary">New</.badge>
      </div>
    </div>
  </:item>
</.timeline>
```

Use the marker slot only when every marker needs custom markup.

## File Upload

Use Phoenix `allow_upload/3` in the parent LiveView and pass the upload config
to `file_upload/1`.

```elixir
def mount(_params, _session, socket) do
  {:ok,
   allow_upload(socket, :avatar,
     accept: ~w(.jpg .jpeg .png),
     max_entries: 1
   )}
end
```

```heex
<.form for={%{}} class="form" phx-submit="save" phx-change="validate">
  <.file_upload upload={@uploads.avatar} label="Avatar" />
  <.button type="submit">Upload</.button>
</.form>
```

Consume entries with `consume_uploaded_entries/3` in the parent. Do not move
storage or validation logic into the component.

## Menus And Actions

Use `dropdown_menu/1` for click-triggered actions and `context_menu/1` for
right-click actions. Keep command behavior in normal Phoenix events.

```heex
<.dropdown_menu id={"row-#{@row.id}-menu"}>
  <:trigger>
    <.button type="button" variant="ghost" size="sm">Actions</.button>
  </:trigger>

  <.dropdown_item phx-click="edit" phx-value-id={@row.id}>
    Edit
  </.dropdown_item>
  <.dropdown_item phx-click="archive" phx-value-id={@row.id}>
    Archive
  </.dropdown_item>
</.dropdown_menu>
```

Use `phx-value-*` freely through globals; do not assume examples whitelist the
only allowed payload names.

## Empty, Loading, And Error States

Compose page states from primitives instead of bespoke markup each time:

```heex
<.loading_state :if={@loading} message="Loading records..." />

<.empty :if={@records == []}>
  <:title>No records</:title>
  <:description>Create the first record to get started.</:description>
  <:actions><.button phx-click="new">New record</.button></:actions>
</.empty>

<.alert :if={@error} variant="destructive">
  <:title>Unable to load records</:title>
  <:description>{@error}</:description>
</.alert>
```

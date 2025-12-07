defmodule PhxUI.SimpleForm do
  @moduledoc """
  Simple form wrapper component for non-LiveView forms with automatic styling.

  The `.form` class acts as a context selector that enables automatic styling
  for all child input, label, textarea, select, checkbox, radio, and switch elements
  without requiring explicit classes on each element.

  This component provides a simple wrapper that adds the `.form` class to enable
  automatic form element styling. For LiveView forms with changesets,
  use the standard `Phoenix.Component.form/1` and add the `class="form"` attribute.

  ## Supported Elements

  The `.form` class enables automatic styling for:
  - Labels
  - Text, email, password, number inputs
  - File, tel, url, search inputs
  - Date, datetime-local, month, week, time inputs
  - Textareas
  - Selects
  - Checkboxes and radio buttons
  - Range inputs
  - Switches (`input[type='checkbox'][role='switch']`)

  ## Examples

      # Simple HTML form (no changeset)
      <.simple_form class="grid gap-6">
        <div class="grid gap-2">
          <label for="username">Username</label>
          <input type="text" id="username" placeholder="Enter username" />
          <p class="text-muted-foreground text-sm">This is your public display name.</p>
        </div>

        <div class="grid gap-2">
          <label for="email">Email</label>
          <input type="email" id="email" placeholder="m@example.com" />
        </div>

        <div class="grid gap-2">
          <label for="bio">Bio</label>
          <textarea id="bio" placeholder="Tell us about yourself..." rows="3"></textarea>
        </div>

        <button type="submit" class="btn">Submit</button>
      </.simple_form>

      # With Phoenix.Component.form for LiveView integration
      <.form :let={f} for={@changeset} class="form grid gap-6" phx-change="validate" phx-submit="save">
        <div class="grid gap-2">
          <label for={f[:name].id}>Name</label>
          <input type="text" name={f[:name].name} value={f[:name].value} />
        </div>
        <button type="submit" class="btn">Save</button>
      </.form>

      # With action and method for traditional forms
      <.simple_form action="/login" method="post" class="space-y-4">
        <div class="grid gap-2">
          <label for="email">Email</label>
          <input type="email" name="email" id="email" required />
        </div>
        <div class="grid gap-2">
          <label for="password">Password</label>
          <input type="password" name="password" id="password" required />
        </div>
        <button type="submit" class="btn w-full">Sign In</button>
      </.simple_form>
  """

  use Phoenix.Component

  @doc """
  Renders a simple form wrapper with automatic child element styling.

  ## Attributes

  * `class` - Additional CSS classes.
  * All standard form attributes are supported via `:global`.

  ## Slots

  * `inner_block` - Required. The form content.
  """
  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes (string or list)"
  )

  attr(:rest, :global,
    include:
      ~w(id action method phx-change phx-submit phx-trigger-action enctype multipart novalidate),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block,
    required: true,
    doc: "The form content"
  )

  def simple_form(assigns) do
    ~H"""
    <form class={["form", @class]} {@rest}>
      {render_slot(@inner_block)}
    </form>
    """
  end
end

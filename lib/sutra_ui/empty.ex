defmodule SutraUI.Empty do
  @moduledoc """
  Display empty states with icons, titles, descriptions, and actions.

  Empty states are shown when there's no data to display, providing users with
  context and potential actions they can take.

  ## Examples

      <.empty>
        <:icon>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-6"><path d="M10 10.5 8 8l4-4 4 4-2 2.5"/><path d="M14 10.5 16 8l-4-4-4 4 2 2.5"/><path d="M4 22V4c0-.5.2-1 .6-1.4C5 2.2 5.5 2 6 2h12c.5 0 1 .2 1.4.6.4.4.6.9.6 1.4v18l-4-3-4 3-4-3Z"/></svg>
        </:icon>
        <:title>No Projects Yet</:title>
        <:description>
          You haven't created any projects yet. Get started by creating your first project.
        </:description>
        <:actions>
          <button class="btn">Create Project</button>
        </:actions>
      </.empty>

      <.empty variant="outline">
        <:icon>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-6"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>
        </:icon>
        <:title>Cloud Storage Empty</:title>
        <:description>Upload files to access them anywhere.</:description>
      </.empty>
  """

  use Phoenix.Component

  @doc """
  Renders an empty state component.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default outline),
    doc: "The visual variant of the empty state"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:icon, doc: "Optional icon or image slot displayed above the title")
  slot(:title, required: true, doc: "The empty state title (h3 heading)")
  slot(:description, doc: "Optional description text providing context")
  slot(:actions, doc: "Optional actions section for buttons or other interactive elements")
  slot(:footer, doc: "Optional footer slot for additional links or information")

  def empty(assigns) do
    ~H"""
    <div
      class={[variant_class(@variant), @class]}
      {@rest}
    >
      <header>
        <%= if @icon != [] do %>
          <div class="empty-icon">
            {render_slot(@icon)}
          </div>
        <% end %>
        <h3>{render_slot(@title)}</h3>
        <%= if @description != [] do %>
          <p>
            {render_slot(@description)}
          </p>
        <% end %>
      </header>
      <%= if @actions != [] do %>
        <section>
          {render_slot(@actions)}
        </section>
      <% end %>
      <%= if @footer != [] do %>
        {render_slot(@footer)}
      <% end %>
    </div>
    """
  end

  defp variant_class("default"), do: "empty"
  defp variant_class("outline"), do: "empty-outline"
end

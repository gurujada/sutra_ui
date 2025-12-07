defmodule PhxUI.Empty do
  @moduledoc """
  Display empty states with icons, titles, descriptions, and actions.

  Empty states are shown when there's no data to display, providing users with
  context and potential actions they can take.

  ## Examples

      <.empty>
        <:icon><.icon name="lucide-folder-code" /></:icon>
        <:title>No Projects Yet</:title>
        <:description>
          You haven't created any projects yet. Get started by creating your first project.
        </:description>
        <:actions>
          <button class="btn">Create Project</button>
        </:actions>
      </.empty>

      <.empty variant="outline">
        <:icon><.icon name="lucide-cloud" /></:icon>
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

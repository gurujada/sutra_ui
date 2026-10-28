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

      # Short form: a title, one line, one action
      <.empty>
        <:title>No projects yet</:title>
        Create one to get started.
        <:action><.button>New project</.button></:action>
      </.empty>

      # One quiet line inside a panel or list
      <.empty variant="inline">
        <:title>No comments</:title>
        Be the first to reply.
      </.empty>

      <.empty variant="outline">
        <:icon>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-6"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>
        </:icon>
        <:title>Cloud Storage Empty</:title>
        <:description>Upload files to access them anywhere.</:description>
      </.empty>

  ## Variants

  - `default` - A centred block for a whole list or page
  - `outline` - The same inside a dashed border
  - `inline` - One quiet line (icon, title, text, action) inside a panel or list

  An empty state is at most an icon, a short title, one line and one action. Give the line as
  the inner block (or the `description` slot) and the action as `action` (or `actions`).
  """

  use Phoenix.Component

  @doc """
  Renders an empty state component.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default outline inline),
    doc: "The visual variant of the empty state"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, doc: "One line: why it is empty or what fills it")

  slot(:icon, doc: "Optional icon or image slot displayed above the title")
  slot(:title, required: true, doc: "The empty state title (h3 heading)")
  slot(:description, doc: "Optional description text providing context")
  slot(:actions, doc: "Optional actions section for buttons or other interactive elements")
  slot(:action, doc: "At most one action (same place as `actions`)")
  slot(:footer, doc: "Optional footer slot for additional links or information")

  def empty(%{variant: "inline"} = assigns) do
    assigns = assign_line(assigns)

    ~H"""
    <div class={["empty-inline", @class]} data-variant="inline" {@rest}>
      <span :if={@icon != []} class="empty-icon" aria-hidden="true">{render_slot(@icon)}</span>
      <span class="empty-title">{render_slot(@title)}</span>
      <span :if={@line} class="empty-text">{@line}</span>
      <span :if={@actions != [] || @action != []} class="empty-action">
        {render_slot(@actions)}{render_slot(@action)}
      </span>
    </div>
    """
  end

  def empty(assigns) do
    assigns = assign_line(assigns)

    ~H"""
    <div class={[variant_class(@variant), @class]} data-variant={@variant} {@rest}>
      <header>
        <%= if @icon != [] do %>
          <div class="empty-icon">
            {render_slot(@icon)}
          </div>
        <% end %>
        <h3>{render_slot(@title)}</h3>
        <p :if={@line}>{@line}</p>
      </header>
      <%= if @actions != [] || @action != [] do %>
        <section>
          {render_slot(@actions)}{render_slot(@action)}
        </section>
      <% end %>
      <%= if @footer != [] do %>
        {render_slot(@footer)}
      <% end %>
    </div>
    """
  end

  # The one line: the `description` slot, else the inner block. A call with named slots always
  # has an inner block, empty when it holds only those slots, so it counts only with text.
  defp assign_line(assigns) do
    line =
      if assigns.description != [],
        do: ~H"{render_slot(@description)}",
        else: ~H"{render_slot(@inner_block)}"

    text = line |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary() |> String.trim()
    assign(assigns, :line, if(text == "", do: nil, else: line))
  end

  defp variant_class("default"), do: "empty"
  defp variant_class("outline"), do: "empty-outline"
end

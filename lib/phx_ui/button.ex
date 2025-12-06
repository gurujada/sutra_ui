defmodule PhxUI.Button do
  @moduledoc """
  A versatile button component with multiple variants and sizes.

  Buttons can be rendered as `<button>`, `<a>`, or Phoenix LiveView navigation links.
  They support multiple variants, sizes, and states including loading and disabled.

  ## Variants

  - `primary` (default) - Primary action button with solid background
  - `secondary` - Secondary action with muted background
  - `destructive` - Destructive actions (delete, remove)
  - `outline` - Button with border and transparent background
  - `ghost` - Minimal button with no background until hover
  - `link` - Styled as an underlined link

  ## Sizes

  - `default` - Standard button height
  - `sm` - Small button
  - `lg` - Large button
  - `icon` - Square icon-only button

  ## Navigation

  The button can function as a link:
  - `navigate` - Client-side navigation (new LiveView)
  - `patch` - Client-side navigation (same LiveView)
  - `href` - Regular link or external URL

  ## Accessibility

  - Icon-only buttons (`size="icon"`) should include `aria-label`
  - Loading state automatically sets `aria-busy="true"`
  - Disabled state uses the `disabled` attribute

  ## Examples

      # Basic button
      <.button>Click me</.button>

      # Variants
      <.button variant="secondary">Secondary</.button>
      <.button variant="destructive">Delete</.button>
      <.button variant="outline">Outline</.button>
      <.button variant="ghost">Ghost</.button>
      <.button variant="link">Link</.button>

      # Sizes
      <.button size="sm">Small</.button>
      <.button size="lg">Large</.button>

      # Icon button (MUST include aria-label)
      <.button size="icon" aria-label="Close">
        <.icon name="hero-x-mark" />
      </.button>

      # Loading state
      <.button loading>Processing...</.button>

      # Navigation
      <.button navigate={~p"/users"}>View Users</.button>
      <.button patch={~p"/users/1/edit"}>Edit</.button>
      <.button href="https://example.com">External</.button>

      # Form submit
      <.button type="submit">Submit</.button>
  """

  use Phoenix.Component

  @doc """
  Renders a button component.

  ## Attributes

  * `variant` - Visual style. One of `primary`, `secondary`, `destructive`, `outline`, `ghost`, `link`. Defaults to `primary`.
  * `size` - Size variant. One of `default`, `sm`, `lg`, `icon`. Defaults to `default`.
  * `type` - Button type. One of `button`, `submit`, `reset`. Defaults to `button`.
  * `loading` - Shows loading state and disables button. Defaults to `false`.
  * `disabled` - Disables the button. Defaults to `false`.
  * `navigate` - LiveView navigate path.
  * `patch` - LiveView patch path.
  * `href` - Regular link URL.
  * `class` - Additional CSS classes.

  ## Slots

  * `inner_block` - Required. The button content.
  """
  attr(:variant, :string,
    default: "primary",
    values: ~w(primary secondary destructive outline ghost link),
    doc: "Visual style variant"
  )

  attr(:size, :string,
    default: "default",
    values: ~w(default sm lg icon),
    doc: "Size variant"
  )

  attr(:type, :string,
    default: "button",
    values: ~w(button submit reset),
    doc: "Button type attribute"
  )

  attr(:loading, :boolean,
    default: false,
    doc: "Loading state - disables button and sets aria-busy"
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Disabled state"
  )

  attr(:navigate, :string,
    default: nil,
    doc: "LiveView navigate path"
  )

  attr(:patch, :string,
    default: nil,
    doc: "LiveView patch path"
  )

  attr(:href, :string,
    default: nil,
    doc: "Regular link URL"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include:
      ~w(id name value form aria-label aria-pressed aria-describedby aria-expanded aria-controls aria-haspopup phx-click phx-target phx-value-id phx-disable-with download),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true, doc: "Button content")

  def button(assigns) do
    assigns =
      assigns
      |> assign(:is_disabled, assigns.disabled || assigns.loading)
      |> assign(:aria_busy, if(assigns.loading, do: "true"))
      |> assign(:classes, button_class(assigns.variant, assigns.size, assigns.class))

    cond do
      assigns.navigate ->
        ~H"""
        <.link navigate={@navigate} class={@classes} {@rest}>
          {render_slot(@inner_block)}
        </.link>
        """

      assigns.patch ->
        ~H"""
        <.link patch={@patch} class={@classes} {@rest}>
          {render_slot(@inner_block)}
        </.link>
        """

      assigns.href ->
        ~H"""
        <a href={@href} class={@classes} {@rest}>
          {render_slot(@inner_block)}
        </a>
        """

      true ->
        ~H"""
        <button type={@type} disabled={@is_disabled} aria-busy={@aria_busy} class={@classes} {@rest}>
          {render_slot(@inner_block)}
        </button>
        """
    end
  end

  # Build simple semantic CSS class based on variant/size
  # CSS classes defined in phx_ui.css handle all styling via @apply
  defp button_class(variant, size, extra_class) do
    base =
      case {size, variant} do
        # Icon buttons
        {"icon", "primary"} -> "btn-icon"
        {"icon", "secondary"} -> "btn-icon-secondary"
        {"icon", "destructive"} -> "btn-icon-destructive"
        {"icon", "outline"} -> "btn-icon-outline"
        {"icon", "ghost"} -> "btn-icon-ghost"
        {"icon", "link"} -> "btn-icon-link"
        # Small buttons
        {"sm", "primary"} -> "btn-sm"
        {"sm", "secondary"} -> "btn-sm-secondary"
        {"sm", "destructive"} -> "btn-sm-destructive"
        {"sm", "outline"} -> "btn-sm-outline"
        {"sm", "ghost"} -> "btn-sm-ghost"
        {"sm", "link"} -> "btn-sm-link"
        # Large buttons
        {"lg", "primary"} -> "btn-lg"
        {"lg", "secondary"} -> "btn-lg-secondary"
        {"lg", "destructive"} -> "btn-lg-destructive"
        {"lg", "outline"} -> "btn-lg-outline"
        {"lg", "ghost"} -> "btn-lg-ghost"
        {"lg", "link"} -> "btn-lg-link"
        # Default size buttons
        {"default", "primary"} -> "btn"
        {"default", "secondary"} -> "btn-secondary"
        {"default", "destructive"} -> "btn-destructive"
        {"default", "outline"} -> "btn-outline"
        {"default", "ghost"} -> "btn-ghost"
        {"default", "link"} -> "btn-link"
      end

    [base, extra_class]
  end
end

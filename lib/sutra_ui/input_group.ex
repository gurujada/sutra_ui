defmodule SutraUI.InputGroup do
  @moduledoc """
  Display additional information or actions attached to an input or textarea.

  Input groups allow you to add prefixes, suffixes, and footers to form inputs
  using relative/absolute positioning. This component handles positioning and
  provides consistent styling patterns.

  ## Padding Guidelines

  You need to manually add padding to the input/textarea to make room for prefix/suffix content:

  - Icon prefix: `pl-9`
  - Icon suffix: `pr-9`
  - Text prefix (short): `pl-7`
  - Text suffix (short): `pr-12`
  - Text prefix (long): `pl-15` or `pl-21`
  - Text suffix (long): `pr-15`, `pr-20`, or `pr-30`
  - Multiple icons: adjust based on count (e.g., `pr-16` for two icons)
  - Textarea footer: `pb-12`

  ## Slot Types

  - `type="icon"` - For icons (adds icon sizing styles)
  - `type="interactive"` - For buttons or clickable elements (enables pointer events)
  - No type (default) - For text content

  ## Examples

      # Icon prefix
      <.input_group>
        <:prefix type="icon">
          <.icon name="lucide-search" />
        </:prefix>
        <input type="text" class="input pl-9" placeholder="Search..." />
      </.input_group>

      # Text prefix and suffix
      <.input_group>
        <:prefix>$</:prefix>
        <:suffix>USD</:suffix>
        <input type="text" class="input pl-7 pr-12" placeholder="0.00" />
      </.input_group>

      # Interactive button suffix
      <.input_group>
        <:suffix type="interactive">
          <button type="button" class="btn-icon-ghost size-6">
            <.icon name="lucide-clipboard" />
          </button>
        </:suffix>
        <input type="text" class="input pr-9" value="https://example.com" readonly />
      </.input_group>

      # With textarea and footer
      <.input_group>
        <textarea class="textarea min-h-27 pb-12" placeholder="Enter message..."></textarea>
        <:footer>
          <button type="button" class="btn-icon-outline rounded-full size-6">
            <.icon name="lucide-plus" />
          </button>
          <div class="text-muted-foreground text-sm ml-auto">52% used</div>
        </:footer>
      </.input_group>
  """

  use Phoenix.Component

  @doc """
  Renders an input group with optional prefix and suffix content.

  ## Attributes

  * `class` - Additional CSS classes for the wrapper.

  ## Slots

  * `inner_block` - Required. The input or textarea element with appropriate padding classes.
  * `prefix` - Content to display before the input (left side). Accepts `type` attribute.
  * `suffix` - Content to display after the input (right side). Accepts `type` attribute.
  * `footer` - Content to display at the bottom of textarea inputs.
  """
  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes for the wrapper"
  )

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes for the wrapper"
  )

  slot :prefix, doc: "Content to display before the input (left side)" do
    attr(:type, :string, values: ~w(icon interactive text))
  end

  slot :suffix, doc: "Content to display after the input (right side)" do
    attr(:type, :string, values: ~w(icon interactive text))
  end

  slot(:footer, doc: "Content to display at the bottom of textarea inputs")

  slot(:inner_block,
    required: true,
    doc: "The input or textarea element with appropriate padding classes"
  )

  def input_group(assigns) do
    ~H"""
    <div class={["input-group", @class]} {@rest}>
      {render_slot(@inner_block)}

      <div :for={prefix <- @prefix} class={prefix_class(prefix)}>
        {render_slot(prefix)}
      </div>

      <div :for={suffix <- @suffix} class={suffix_class(suffix)}>
        {render_slot(suffix)}
      </div>

      <footer :for={footer <- @footer} role="group" class="input-group-footer">
        {render_slot(footer)}
      </footer>
    </div>
    """
  end

  @doc """
  Renders a horizontal input group with prefix/suffix labels outside the input.

  This is for cases where you want to visually group an input with external labels,
  like "https://" [input] ".com".

  ## Examples

      <.input_group_horizontal>
        <:prefix_label>https://</:prefix_label>
        <:suffix_label>.com</:suffix_label>
        <input type="text" class="input rounded-none" />
      </.input_group_horizontal>
  """
  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:prefix_label, doc: "Label content before the input")
  slot(:suffix_label, doc: "Label content after the input")

  slot(:inner_block,
    required: true,
    doc: "The input element (typically with rounded-none class)"
  )

  def input_group_horizontal(assigns) do
    ~H"""
    <div class={["input-group-horizontal", @class]} {@rest}>
      <label :for={label <- @prefix_label} class="input-group-label input-group-label-start">
        {render_slot(label)}
      </label>

      {render_slot(@inner_block)}

      <div :for={label <- @suffix_label} class="input-group-label input-group-label-end">
        {render_slot(label)}
      </div>
    </div>
    """
  end

  defp prefix_class(%{type: "icon"}), do: "input-group-prefix-icon"
  defp prefix_class(%{type: "interactive"}), do: "input-group-prefix-interactive"
  defp prefix_class(%{type: "text"}), do: "input-group-prefix input-group-text"
  defp prefix_class(_), do: "input-group-prefix input-group-text"

  defp suffix_class(%{type: "icon"}), do: "input-group-suffix-icon"
  defp suffix_class(%{type: "interactive"}), do: "input-group-suffix-interactive"
  defp suffix_class(%{type: "text"}), do: "input-group-suffix input-group-text"
  defp suffix_class(_), do: "input-group-suffix input-group-text"
end

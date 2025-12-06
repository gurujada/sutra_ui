defmodule PhxUI.Slider do
  @moduledoc """
  An input where the user selects a value from within a given range.

  Uses a native `<input type="range">` element with custom styling and
  a colocated JavaScript hook to update the visual progress indicator.

  ## Accessibility

  - Uses semantic `<input type="range">` element
  - Supports `aria-label` or `aria-labelledby` for labeling
  - Supports `aria-valuemin`, `aria-valuemax`, `aria-valuenow`, `aria-valuetext`
  - Keyboard accessible (Arrow keys, Home, End, Page Up, Page Down)
  - Announces value changes to screen readers

  ## Colocated Hook

  This component includes a colocated JavaScript hook (`.Slider`) that updates:
  - The visual progress indicator via CSS custom property `--slider-value`
  - The `aria-valuenow` attribute as the value changes

  The hook is automatically available when you import colocated hooks in your app.js.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a slider component.

  ## Examples

      # Basic slider
      <.slider id="volume-slider" min="0" max="100" value="50" />

      # With label
      <label for="volume-slider">Volume</label>
      <.slider id="volume-slider" min="0" max="100" value="50" name="volume" />

      # With aria-label
      <.slider
        id="volume-slider"
        min="0"
        max="100"
        value="50"
        aria-label="Volume control"
      />

      # Temperature slider with fractional steps
      <.slider
        id="temperature-slider"
        min="-10"
        max="40"
        step="0.5"
        value="20"
        name="temperature"
        aria-label="Temperature in Celsius"
      />

      # Disabled slider
      <.slider
        id="brightness-slider"
        min="0"
        max="100"
        value="75"
        disabled
      />

      # With value text for screen readers
      <.slider
        id="progress-slider"
        min="0"
        max="100"
        value="75"
        aria-valuetext="75 percent complete"
      />
  """

  attr(:id, :string, required: true, doc: "Unique identifier for the slider (required for hook)")
  attr(:min, :string, default: "0", doc: "Minimum value")
  attr(:max, :string, default: "100", doc: "Maximum value")
  attr(:step, :string, default: "1", doc: "Step increment")
  attr(:value, :string, default: "50", doc: "Current value")
  attr(:name, :string, default: nil, doc: "Form input name")
  attr(:disabled, :boolean, default: false, doc: "Whether the slider is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include:
      ~w(form phx-change phx-blur phx-focus aria-label aria-labelledby aria-describedby aria-valuetext),
    doc: "Additional HTML attributes including ARIA"
  )

  def slider(assigns) do
    # Calculate percentage for CSS custom property
    {min, _} = Float.parse("#{assigns.min}")
    {max, _} = Float.parse("#{assigns.max}")
    {value, _} = Float.parse("#{assigns.value}")

    percent = if max == min, do: 0, else: (value - min) / (max - min) * 100
    assigns = assign(assigns, :percent, "#{percent}%")

    ~H"""
    <input
      type="range"
      id={@id}
      class={["slider", @class]}
      min={@min}
      max={@max}
      step={@step}
      value={@value}
      name={@name}
      disabled={@disabled}
      aria-valuemin={@min}
      aria-valuemax={@max}
      aria-valuenow={@value}
      style={"--slider-value: #{@percent}"}
      phx-hook=".Slider"
      {@rest}
    />

    <script :type={ColocatedHook} name=".Slider">
      export default {
        mounted() {
          this.updateSlider();
          this.el.addEventListener('input', () => this.updateSlider());
        },

        updated() {
          this.updateSlider();
        },

        updateSlider() {
          const min = parseFloat(this.el.min || 0);
          const max = parseFloat(this.el.max || 100);
          const value = parseFloat(this.el.value);
          const percent = (max === min) ? 0 : ((value - min) / (max - min)) * 100;
          this.el.style.setProperty('--slider-value', `${percent}%`);

          // Update ARIA value
          this.el.setAttribute('aria-valuenow', value);
        }
      }
    </script>
    """
  end
end

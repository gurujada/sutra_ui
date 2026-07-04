defmodule SutraUI.Slider do
  @moduledoc """
  An input where the user selects a value from within a given range.

  Uses a native `<input type="range">` element with custom styling and
  a colocated JavaScript hook to update the visual progress indicator.

  ## Value Types

  The slider formats its rendered value from the `step` attribute so the
  native range input, ARIA value, and associated `<output>` use consistent
  precision:

  - Integer step (e.g., `step={1}`, `step={5}`) -> integer-like values
  - Float step (e.g., `step={0.1}`, `step={0.5}`) -> decimal values with matching precision

  ## Examples

      # Basic slider (integer mode)
      <.slider id="volume-slider" min={0} max={100} value={50} />

      # With label
      <div>
        <label for="volume-slider">Volume</label>
        <span><output for="volume-slider">50</output>%</span>
      </div>
      <.slider id="volume-slider" min={0} max={100} value={50} name="volume" />

      # Float mode - step determines precision
      <.slider
        id="temperature-slider"
        min={-10}
        max={40}
        step={0.5}
        value={20.5}
        name="temperature"
        aria-label="Temperature in Celsius"
      />

      # High precision floats
      <.slider id="weight" min={0} max={10} step={0.01} value={5.25} />

      # Disabled slider
      <.slider
        id="brightness-slider"
        min={0}
        max={100}
        value={75}
        disabled
      />

      # With value text for screen readers
      <.slider
        id="progress-slider"
        min={0}
        max={100}
        value={75}
        aria-valuetext="75 percent complete"
      />

  ## Accessibility

  - Uses semantic `<input type="range">` element
  - Supports `aria-label` or `aria-labelledby` for labeling
  - Supports `aria-valuemin`, `aria-valuemax`, `aria-valuenow`, `aria-valuetext`
  - Keyboard accessible (Arrow keys, Home, End, Page Up, Page Down)
  - Exposes current value through the native range input and `aria-valuenow`

  ## Colocated Hook

  This component includes a colocated JavaScript hook (`.Slider`) that updates:
  - The visual progress indicator via CSS custom property `--slider-value`
  - The `aria-valuenow` attribute as the value changes
  - Associated `<output for="slider-id">` elements for instant value display

  The hook is rendered as a runtime colocated hook with the component.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a slider component.

  ## Attributes

  - `id` - Unique identifier for the slider (required for hook)
  - `min` - Minimum value (default: 0)
  - `max` - Maximum value (default: 100)
  - `step` - Step increment (default: 1). Integer step = integer values, float step = float values.
  - `value` - Current value (default: 50)
  - `name` - Form input name
  - `disabled` - Whether the slider is disabled
  - `class` - Additional CSS classes
  """

  attr(:id, :string, required: true, doc: "Unique identifier for the slider (required for hook)")
  attr(:min, :any, default: 0, doc: "Minimum value (integer or float)")
  attr(:max, :any, default: 100, doc: "Maximum value (integer or float)")
  attr(:step, :any, default: 1, doc: "Step increment. Integer = integer mode, float = float mode")
  attr(:value, :any, default: 50, doc: "Current value")
  attr(:name, :string, default: nil, doc: "Form input name")
  attr(:disabled, :boolean, default: false, doc: "Whether the slider is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include:
      ~w(form phx-change phx-blur phx-focus aria-label aria-labelledby aria-describedby aria-valuetext aria-invalid min max step),
    doc: "Additional HTML attributes including ARIA"
  )

  def slider(assigns) do
    # Convert all numeric values to floats internally
    min = to_float(assigns.min)
    max = to_float(assigns.max)
    step = normalize_step(assigns.step)
    value = to_float(assigns.value)

    # Calculate precision from step
    precision = infer_precision(assigns.step)

    # Ensure value is within bounds and snapped to step
    value = snap_to_step(clamp(value, min, max), step, min)

    # Format value for the DOM based on step precision.
    formatted_value = format_value(value, precision)

    # Calculate percentage for CSS custom property
    percent = if max == min, do: 0.0, else: (value - min) / (max - min) * 100

    assigns =
      assigns
      |> assign(:min, min)
      |> assign(:max, max)
      |> assign(:step, step)
      |> assign(:precision, precision)
      |> assign(:value, formatted_value)
      |> assign(:percent, "#{percent}%")

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
      data-precision={@precision}
      style={"--slider-value: #{@percent}"}
      phx-hook=".Slider"
      {@rest}
    />

    <script :type={ColocatedHook} name=".Slider" runtime>
      {
        mounted() {
          this.precision = parseInt(this.el.dataset.precision) || 0;
          this.updateSlider();
          this.inputHandler = () => this.updateSlider();
          this.el.addEventListener('input', this.inputHandler);
        },

        updated() {
          this.precision = parseInt(this.el.dataset.precision) || 0;
          this.updateSlider();
        },

        destroyed() {
          this.el.removeEventListener('input', this.inputHandler);
        },

        formatValue(value) {
          return this.precision === 0 ? Math.round(value) : parseFloat(value.toFixed(this.precision));
        },

        updateSlider() {
          const min = parseFloat(this.el.min || 0);
          const max = parseFloat(this.el.max || 100);
          const value = parseFloat(this.el.value);
          const percent = (max === min) ? 0 : ((value - min) / (max - min)) * 100;
          this.el.style.setProperty('--slider-value', `${percent}%`);

          // Format value based on precision
          const formattedValue = this.formatValue(value);

          // Update ARIA value
          this.el.setAttribute('aria-valuenow', formattedValue);

          // Keep standard associated outputs in sync without a server roundtrip.
          this.updateOutputs(formattedValue);
        },

        updateOutputs(value) {
          if (!this.el.id) return;

          const root = this.el.getRootNode?.() || document;
          const outputs = root.querySelectorAll?.('output[for]') || [];

          outputs.forEach((output) => {
            const ids = (output.getAttribute('for') || '').split(/\s+/);

            if (ids.includes(this.el.id)) {
              output.value = value;
              output.textContent = value;
            }
          });
        }
      }
    </script>
    """
  end

  # Convert any numeric type to float
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(value) when is_float(value), do: value

  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp to_float(_), do: 0.0

  defp normalize_step(step) do
    step
    |> to_float()
    |> case do
      value when value > 0 -> value
      _value -> 1.0
    end
  end

  # Infer precision from step value
  defp infer_precision(step) when is_integer(step), do: 0

  defp infer_precision(step) when is_float(step) do
    step
    |> Float.to_string()
    |> String.split(".")
    |> case do
      [_, decimal] -> String.length(decimal)
      _ -> 0
    end
  end

  defp infer_precision(_), do: 0

  # Format value for the DOM based on precision.
  defp format_value(value, 0), do: trunc(value)
  defp format_value(value, precision), do: Float.round(value, precision)

  # Clamp value to bounds
  defp clamp(value, min, max) do
    value
    |> Kernel.max(min)
    |> Kernel.min(max)
  end

  # Snap value to nearest step
  defp snap_to_step(value, step, min) do
    steps = Float.round((value - min) / step)
    min + steps * step
  end
end

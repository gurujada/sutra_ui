defmodule PhxUI.RangeSlider do
  @moduledoc """
  A dual-handle range slider for selecting a range of values.

  Similar to noUiSlider, this component provides two draggable handles
  to select a minimum and maximum value within a defined range.

  ## Value Types

  The slider automatically determines whether to emit integer or float values
  based on the `step` attribute:

  - Integer step (e.g., `step={1}`, `step={5}`) → emits integers
  - Float step (e.g., `step={0.1}`, `step={0.5}`) → emits floats with matching precision

  ## Examples

      # Basic range slider (integer mode)
      <.range_slider name="price" min={0} max={1000} value_min={200} value_max={800} />

      # With step increments (integer mode)
      <.range_slider name="age" min={0} max={100} step={5} value_min={20} value_max={60} />

      # Float mode - step determines precision
      <.range_slider name="rating" min={0} max={5} step={0.5} value_min={1.5} value_max={4.0} />

      # High precision floats
      <.range_slider name="weight" min={0} max={10} step={0.01} value_min={2.50} value_max={7.75} />

      # With custom formatting for display (does not affect emitted values)
      <.range_slider name="price" min={0} max={100} format={&"$\#{&1}"} />

      # With tooltips always visible
      <.range_slider name="rating" min={1} max={10} value_min={3} value_max={8} tooltips />

      # Emit events while dragging (debounced)
      <.range_slider name="budget" min={0} max={10000} on_slide="budget_slide" debounce={100} />

      # Emit event only on release
      <.range_slider name="budget" min={0} max={10000} on_change="budget_changed" />

      # Disabled state
      <.range_slider name="locked" min={0} max={100} value_min={25} value_max={75} disabled />

  ## Event Modes

  The slider supports different event modes similar to noUiSlider:

  - `on_slide` - Fires while dragging (debounced) - pushEvent style
  - `on_change` - Fires on release - pushEvent style

  Event payload includes values formatted based on step:
  - Integer step: `%{name: "field", min: 200, max: 800, field_min: 200, field_max: 800}`
  - Float step: `%{name: "field", min: 2.5, max: 8.0, field_min: 2.5, field_max: 8.0}`

  ## Form Integration

  The component renders two hidden inputs:
  - `{name}_min` - The minimum selected value
  - `{name}_max` - The maximum selected value

  These are automatically submitted with forms.

  ## Setting Values from Server

  The slider automatically syncs with server-pushed values via the `updated()` hook.
  Simply update the assigns and the slider will reflect the new values.

  ## Accessibility

  - Full keyboard support: Tab to focus, Arrow keys to adjust values
  - ARIA attributes for screen readers
  - Visible focus states
  - Touch-friendly handle sizes
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a dual-handle range slider.

  ## Attributes

  - `name` - Base name for the hidden inputs (required)
  - `min` - Minimum value of the range (default: 0)
  - `max` - Maximum value of the range (default: 100)
  - `step` - Step increment for values (default: 1). Integer step = integer values, float step = float values.
  - `value_min` - Current minimum selected value (default: 25% of range)
  - `value_max` - Current maximum selected value (default: 75% of range)
  - `format` - Optional function to format displayed values (does not affect emitted values)
  - `tooltips` - Show value tooltips on handles (default: false)
  - `disabled` - Disable the slider (default: false)
  - `on_slide` - Event to push while dragging (debounced)
  - `on_change` - Event to push on release
  - `debounce` - Debounce interval in ms for slide events (default: 50)
  - `class` - Additional CSS classes
  - Global attributes including `phx-target`, etc.
  """
  attr(:name, :string, required: true, doc: "Base name for hidden inputs")
  attr(:id, :string, default: nil, doc: "Unique identifier")
  attr(:min, :any, default: 0, doc: "Minimum range value (integer or float)")
  attr(:max, :any, default: 100, doc: "Maximum range value (integer or float)")
  attr(:step, :any, default: 1, doc: "Step increment. Integer = integer mode, float = float mode")
  attr(:value_min, :any, default: nil, doc: "Current minimum value")
  attr(:value_max, :any, default: nil, doc: "Current maximum value")
  attr(:format, :any, default: nil, doc: "Optional (value) -> string function for display")
  attr(:tooltips, :boolean, default: false, doc: "Show value tooltips")
  attr(:disabled, :boolean, default: false, doc: "Disable the slider")
  attr(:on_slide, :string, default: nil, doc: "Event to push while dragging")
  attr(:on_change, :string, default: nil, doc: "Event to push on release")
  attr(:debounce, :integer, default: 50, doc: "Debounce interval in ms for slide events")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  def range_slider(assigns) do
    # Convert all numeric values to floats internally
    min = to_float(assigns.min)
    max = to_float(assigns.max)
    step = to_float(assigns.step)

    # Calculate precision from step
    precision = infer_precision(assigns.step)

    # Calculate default values if not provided (25% and 75% of range)
    range = max - min
    default_min = min + range * 0.25
    default_max = max - range * 0.25

    # Use provided values or defaults
    value_min = if assigns.value_min, do: to_float(assigns.value_min), else: default_min
    value_max = if assigns.value_max, do: to_float(assigns.value_max), else: default_max

    # Ensure values are within bounds and snapped to step
    value_min = snap_to_step(clamp(value_min, min, max), step, min)
    value_max = snap_to_step(clamp(value_max, min, max), step, min)

    # Ensure value_min <= value_max
    value_min = Kernel.min(value_min, value_max)

    id = assigns.id || "range-slider-#{assigns.name}"

    # Calculate percentages for positioning
    percent_min = calculate_percent(value_min, min, max)
    percent_max = calculate_percent(value_max, min, max)

    # Format values for display
    format_fn = assigns.format || (&format_value(&1, precision))
    display_min = format_fn.(value_min)
    display_max = format_fn.(value_max)

    # Format values for emission (integers or floats based on step)
    emit_min = format_for_emit(value_min, precision)
    emit_max = format_for_emit(value_max, precision)

    assigns =
      assigns
      |> assign(:min, min)
      |> assign(:max, max)
      |> assign(:step, step)
      |> assign(:precision, precision)
      |> assign(:value_min, emit_min)
      |> assign(:value_max, emit_max)
      |> assign(:display_min, display_min)
      |> assign(:display_max, display_max)
      |> assign(:id, id)
      |> assign(:percent_min, percent_min)
      |> assign(:percent_max, percent_max)

    ~H"""
    <div
      id={@id}
      class={["range-slider", @disabled && "range-slider-disabled", @class]}
      phx-hook=".RangeSlider"
      data-min={@min}
      data-max={@max}
      data-step={@step}
      data-precision={@precision}
      data-value-min={@value_min}
      data-value-max={@value_max}
      data-name={@name}
      data-on-slide={@on_slide}
      data-on-change={@on_change}
      data-debounce={@debounce}
      data-tooltips={@tooltips}
      data-disabled={@disabled}
      {@rest}
    >
      <div class="range-slider-track">
        <div
          class="range-slider-range"
          style={"left: #{@percent_min}%; width: #{@percent_max - @percent_min}%"}
        >
        </div>
      </div>

      <div
        class="range-slider-thumb"
        data-index="0"
        tabindex={if @disabled, do: "-1", else: "0"}
        role="slider"
        aria-label="Minimum value"
        aria-valuemin={@min}
        aria-valuemax={@max}
        aria-valuenow={@value_min}
        style={"left: #{@percent_min}%"}
      >
        <div :if={@tooltips} class="range-slider-tooltip">
          {@display_min}
        </div>
      </div>

      <div
        class="range-slider-thumb"
        data-index="1"
        tabindex={if @disabled, do: "-1", else: "0"}
        role="slider"
        aria-label="Maximum value"
        aria-valuemin={@min}
        aria-valuemax={@max}
        aria-valuenow={@value_max}
        style={"left: #{@percent_max}%"}
      >
        <div :if={@tooltips} class="range-slider-tooltip">
          {@display_max}
        </div>
      </div>

      <input type="hidden" name={"#{@name}_min"} value={@value_min} />
      <input type="hidden" name={"#{@name}_max"} value={@value_max} />
    </div>

    <script :type={ColocatedHook} name=".RangeSlider">
      export default {
        mounted() {
          this.initializeState();
          this.cacheElements();
          if (!this.disabled) {
            this.setupEventListeners();
          }
        },

        updated() {
          // Sync values from server after LiveView update
          const newMin = parseFloat(this.el.dataset.valueMin);
          const newMax = parseFloat(this.el.dataset.valueMax);
          if (!this.isDragging && (newMin !== this.valueMin || newMax !== this.valueMax)) {
            this.valueMin = newMin;
            this.valueMax = newMax;
            this.updateUI();
          }
        },

        destroyed() {
          this.removeEventListeners();
        },

        initializeState() {
          this.min = parseFloat(this.el.dataset.min);
          this.max = parseFloat(this.el.dataset.max);
          this.step = parseFloat(this.el.dataset.step) || 1;
          this.precision = parseInt(this.el.dataset.precision) || 0;
          this.valueMin = parseFloat(this.el.dataset.valueMin);
          this.valueMax = parseFloat(this.el.dataset.valueMax);
          this.name = this.el.dataset.name;
          this.onSlide = this.el.dataset.onSlide;
          this.onChange = this.el.dataset.onChange;
          this.debounceMs = parseInt(this.el.dataset.debounce) || 50;
          this.tooltips = this.el.dataset.tooltips === 'true';
          this.disabled = this.el.dataset.disabled === 'true';
          this.activeThumb = null;
          this.isDragging = false;
          this.debounceTimer = null;
        },

        cacheElements() {
          this.track = this.el.querySelector('.range-slider-track');
          this.range = this.el.querySelector('.range-slider-range');
          this.thumbs = Array.from(this.el.querySelectorAll('.range-slider-thumb'));
          this.inputs = {
            min: this.el.querySelector('input[name$="_min"]'),
            max: this.el.querySelector('input[name$="_max"]')
          };
        },

        setupEventListeners() {
          // Bind methods for removal later
          this.onMouseDown = this.onMouseDown.bind(this);
          this.onTouchStart = this.onTouchStart.bind(this);
          this.onKeyDown = this.onKeyDown.bind(this);
          this.onTrackClick = this.onTrackClick.bind(this);
          this.onMouseMove = this.onMouseMove.bind(this);
          this.onMouseUp = this.onMouseUp.bind(this);
          this.onTouchMove = this.onTouchMove.bind(this);
          this.onTouchEnd = this.onTouchEnd.bind(this);

          // Mouse/touch events on thumbs
          this.thumbs.forEach((thumb, index) => {
            thumb.addEventListener('mousedown', (e) => this.onMouseDown(e, index));
            thumb.addEventListener('touchstart', (e) => this.onTouchStart(e, index), { passive: false });
            thumb.addEventListener('keydown', (e) => this.onKeyDown(e, index));
          });

          // Track click to jump to position
          this.track.addEventListener('click', this.onTrackClick);

          // Global mouse/touch move and up
          document.addEventListener('mousemove', this.onMouseMove);
          document.addEventListener('mouseup', this.onMouseUp);
          document.addEventListener('touchmove', this.onTouchMove, { passive: false });
          document.addEventListener('touchend', this.onTouchEnd);
        },

        removeEventListeners() {
          document.removeEventListener('mousemove', this.onMouseMove);
          document.removeEventListener('mouseup', this.onMouseUp);
          document.removeEventListener('touchmove', this.onTouchMove);
          document.removeEventListener('touchend', this.onTouchEnd);

          if (this.debounceTimer) {
            clearTimeout(this.debounceTimer);
          }
        },

        onMouseDown(e, index) {
          if (this.disabled) return;
          e.preventDefault();
          e.stopPropagation();
          this.startDrag(index);
        },

        onTouchStart(e, index) {
          if (this.disabled) return;
          e.preventDefault();
          this.startDrag(index);
        },

        startDrag(index) {
          this.isDragging = true;
          this.activeThumb = index;
          this.thumbs[index].classList.add('range-slider-thumb-active');
          this.el.classList.add('range-slider-dragging');
        },

        onMouseMove(e) {
          if (!this.isDragging) return;
          e.preventDefault();
          this.handleDrag(e.clientX);
        },

        onTouchMove(e) {
          if (!this.isDragging) return;
          e.preventDefault();
          this.handleDrag(e.touches[0].clientX);
        },

        handleDrag(clientX) {
          if (this.activeThumb === null) return;

          const value = this.getValueFromClientX(clientX);
          let changed = false;

          if (this.activeThumb === 0) {
            // Min thumb - can't exceed max value
            const newMin = Math.min(value, this.valueMax);
            if (newMin !== this.valueMin) {
              this.valueMin = newMin;
              changed = true;
            }
          } else {
            // Max thumb - can't go below min value
            const newMax = Math.max(value, this.valueMin);
            if (newMax !== this.valueMax) {
              this.valueMax = newMax;
              changed = true;
            }
          }

          if (changed) {
            this.updateUI();
            this.emitSlide();
          }
        },

        onMouseUp(e) {
          this.endDrag();
        },

        onTouchEnd(e) {
          this.endDrag();
        },

        endDrag() {
          if (!this.isDragging) return;

          // Clear any pending debounce
          if (this.debounceTimer) {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = null;
          }

          this.isDragging = false;
          if (this.activeThumb !== null) {
            this.thumbs[this.activeThumb].classList.remove('range-slider-thumb-active');
          }
          this.activeThumb = null;
          this.el.classList.remove('range-slider-dragging');

          // Emit change event on release
          this.emitChange();
        },

        onTrackClick(e) {
          if (this.disabled || this.isDragging) return;

          const value = this.getValueFromClientX(e.clientX);

          // Determine which thumb is closer
          const distToMin = Math.abs(value - this.valueMin);
          const distToMax = Math.abs(value - this.valueMax);

          if (distToMin <= distToMax) {
            this.valueMin = Math.min(value, this.valueMax);
          } else {
            this.valueMax = Math.max(value, this.valueMin);
          }

          this.updateUI();
          this.emitChange();
        },

        onKeyDown(e, index) {
          if (this.disabled) return;

          let delta = 0;
          switch (e.key) {
            case 'ArrowLeft':
            case 'ArrowDown':
              delta = -this.step;
              break;
            case 'ArrowRight':
            case 'ArrowUp':
              delta = this.step;
              break;
            case 'PageDown':
              delta = -this.step * 10;
              break;
            case 'PageUp':
              delta = this.step * 10;
              break;
            case 'Home':
              if (index === 0) {
                this.valueMin = this.min;
              } else {
                this.valueMax = this.valueMin;
              }
              this.updateUI();
              this.emitChange();
              e.preventDefault();
              return;
            case 'End':
              if (index === 0) {
                this.valueMin = this.valueMax;
              } else {
                this.valueMax = this.max;
              }
              this.updateUI();
              this.emitChange();
              e.preventDefault();
              return;
            default:
              return;
          }

          e.preventDefault();

          if (index === 0) {
            const newMin = this.snapToStep(Math.max(this.min, Math.min(this.valueMax, this.valueMin + delta)));
            if (newMin !== this.valueMin) {
              this.valueMin = newMin;
              this.updateUI();
              this.emitChange();
            }
          } else {
            const newMax = this.snapToStep(Math.max(this.valueMin, Math.min(this.max, this.valueMax + delta)));
            if (newMax !== this.valueMax) {
              this.valueMax = newMax;
              this.updateUI();
              this.emitChange();
            }
          }
        },

        getValueFromClientX(clientX) {
          const rect = this.track.getBoundingClientRect();
          const percent = Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100));
          const rawValue = this.min + (percent / 100) * (this.max - this.min);
          return this.snapToStep(rawValue);
        },

        snapToStep(value) {
          const steppedValue = Math.round((value - this.min) / this.step) * this.step + this.min;
          // Round to precision to avoid floating point errors
          const rounded = this.precision === 0 
            ? Math.round(steppedValue) 
            : parseFloat(steppedValue.toFixed(this.precision));
          return Math.max(this.min, Math.min(this.max, rounded));
        },

        formatValue(value) {
          return this.precision === 0 ? Math.round(value) : parseFloat(value.toFixed(this.precision));
        },

        updateUI() {
          const percentMin = ((this.valueMin - this.min) / (this.max - this.min)) * 100;
          const percentMax = ((this.valueMax - this.min) / (this.max - this.min)) * 100;

          // Update thumb positions
          this.thumbs[0].style.left = percentMin + '%';
          this.thumbs[1].style.left = percentMax + '%';

          // Update range bar
          this.range.style.left = percentMin + '%';
          this.range.style.width = (percentMax - percentMin) + '%';

          // Format values for display and emission
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);

          // Update ARIA attributes
          this.thumbs[0].setAttribute('aria-valuenow', formattedMin);
          this.thumbs[1].setAttribute('aria-valuenow', formattedMax);

          // Update hidden inputs
          this.inputs.min.value = formattedMin;
          this.inputs.max.value = formattedMax;

          // Update tooltips if present
          if (this.tooltips) {
            const tooltipMin = this.thumbs[0].querySelector('.range-slider-tooltip');
            const tooltipMax = this.thumbs[1].querySelector('.range-slider-tooltip');
            if (tooltipMin) tooltipMin.textContent = formattedMin;
            if (tooltipMax) tooltipMax.textContent = formattedMax;
          }
        },

        getPayload() {
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);
          return {
            name: this.name,
            min: formattedMin,
            max: formattedMax,
            [`${this.name}_min`]: formattedMin,
            [`${this.name}_max`]: formattedMax
          };
        },

        emitSlide() {
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);

          // Dispatch custom event for vanilla JS listeners
          this.el.dispatchEvent(new CustomEvent('phx-ui:range-slide', {
            detail: { min: formattedMin, max: formattedMax },
            bubbles: true
          }));

          // Debounced pushEvent for on_slide
          if (this.onSlide) {
            if (this.debounceTimer) {
              clearTimeout(this.debounceTimer);
            }
            this.debounceTimer = setTimeout(() => {
              this.pushEvent(this.onSlide, this.getPayload());
            }, this.debounceMs);
          }
        },

        emitChange() {
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);

          // Dispatch custom event for vanilla JS listeners
          this.el.dispatchEvent(new CustomEvent('phx-ui:range-change', {
            detail: { min: formattedMin, max: formattedMax },
            bubbles: true
          }));

          // pushEvent for on_change attribute
          if (this.onChange) {
            this.pushEvent(this.onChange, this.getPayload());
          }

          // Trigger input event on hidden inputs to work with phx-change on parent form
          this.inputs.min.dispatchEvent(new Event('input', { bubbles: true }));
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

  # Format value for display based on precision
  defp format_value(value, 0), do: trunc(value)
  defp format_value(value, precision), do: Float.round(value, precision)

  # Format value for emission (integer or float based on precision)
  defp format_for_emit(value, 0), do: trunc(value)
  defp format_for_emit(value, precision), do: Float.round(value, precision)

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

  defp calculate_percent(value, min, max) do
    range = max - min

    if range == 0 do
      0.0
    else
      Float.round((value - min) / range * 100, 2)
    end
  end
end

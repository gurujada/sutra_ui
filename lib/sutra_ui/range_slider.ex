defmodule SutraUI.RangeSlider do
  @moduledoc """
  A dual-handle range slider for selecting a range of values.

  Similar to noUiSlider, this component provides two draggable handles
  to select a minimum and maximum value within a defined range.

  ## Integer vs Float Mode

  **The `step` attribute determines the type of values emitted by the slider.**
  This is important for database compatibility (e.g., Postgrex expects matching types).

  ### Integer Mode (default)

  When `step` is an integer (e.g., `1`, `5`, `10`), all values are integers:

      # Integer step = integer values
      <.range_slider name="price" min={0} max={1000} step={1} value_min={200} value_max={800} />

      # Event payload: %{"price_min" => 200, "price_max" => 800}
      # Hidden inputs: value="200", value="800"

  ### Float Mode

  When `step` is a float (e.g., `0.1`, `0.5`, `1.0`), all values are floats:

      # Float step = float values
      <.range_slider name="rating" min={0} max={5} step={0.5} value_min={1.5} value_max={4.0} />

      # Event payload: %{"rating_min" => 1.5, "rating_max" => 4.0}
      # Hidden inputs: value="1.5", value="4.0"

  ### Choosing the Right Mode

      # For integer database columns (e.g., price in cents, age, quantity)
      <.range_slider name="price" step={1} ... />      # emits integers

      # For float/decimal database columns (e.g., ratings, percentages, weights)
      <.range_slider name="rating" step={0.5} ... />   # emits floats

      # Want floats but whole number increments? Use a float step like 1.0
      <.range_slider name="score" step={1.0} ... />    # emits floats: 1.0, 2.0, 3.0

  ## Examples

      # Basic range slider (integer mode, step defaults to 1)
      <.range_slider name="price" min={0} max={1000} value_min={200} value_max={800} />

      # With step increments (integer mode)
      <.range_slider name="age" min={0} max={100} step={5} value_min={20} value_max={60} />

      # Float mode with 0.5 increments
      <.range_slider name="rating" min={0} max={5} step={0.5} value_min={1.5} value_max={4.0} />

      # High precision floats (0.01 increments)
      <.range_slider name="weight" min={0} max={10} step={0.01} value_min={2.50} value_max={7.75} />

      # With custom formatting for display (does not affect emitted values)
      <.range_slider name="price" min={0} max={100} format={&"$\#{&1}"} />

      # With tooltips (shown on hover/drag)
      <.range_slider name="rating" min={1} max={10} value_min={3} value_max={8} tooltips />

      # Emit events while dragging (debounced)
      <.range_slider name="budget" min={0} max={10000} on_slide="budget_slide" debounce={100} />

      # Emit event only on release
      <.range_slider name="budget" min={0} max={10000} on_change="budget_changed" />

      # Disabled state
      <.range_slider name="locked" min={0} max={100} value_min={25} value_max={75} disabled />

  ## Pips (Scale Markers)

  Display scale markers below the slider track using the `pips` attribute:

      # Default pips at 0%, 25%, 50%, 75%, 100%
      <.range_slider name="price" min={0} max={100} pips />

      # Custom percentage positions
      <.range_slider name="price" min={0} max={1000} pips={%{mode: :positions, values: [0, 50, 100]}} />

      # Fixed count of evenly distributed pips
      <.range_slider name="price" min={0} max={100} pips={%{mode: :count, count: 5}} />

      # Pip at each step value (good for small ranges)
      <.range_slider name="rating" min={1} max={5} step={1} pips={%{mode: :steps}} />

      # Pips at specific values
      <.range_slider name="price" min={0} max={1000} pips={%{mode: :values, values: [0, 250, 500, 1000]}} />

  ## Event Payloads

  The slider emits events via `on_slide` (during drag) and `on_change` (on release).
  The payload type matches the step type:

      # Integer step (step={1}, step={5}, etc.)
      def handle_event("price_changed", %{"price_min" => 200, "price_max" => 800}, socket)

      # Float step (step={0.5}, step={0.1}, etc.)
      def handle_event("rating_changed", %{"rating_min" => 1.5, "rating_max" => 4.0}, socket)

  ## Form Integration

  The component renders two hidden inputs:
  - `{name}_min` - The minimum selected value
  - `{name}_max` - The maximum selected value

  These are automatically submitted with forms. The value type matches the step type.

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
  - `step` - Step increment (default: 1). **Determines output type: integer step → integers, float step → floats**
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

  attr(:step, :any,
    default: 1,
    doc: "Step increment. Integer (1, 5) emits integers; float (0.5, 1.0) emits floats"
  )

  attr(:value_min, :any, default: nil, doc: "Current minimum value")
  attr(:value_max, :any, default: nil, doc: "Current maximum value")
  attr(:format, :any, default: nil, doc: "Optional (value) -> string function for display")
  attr(:tooltips, :boolean, default: false, doc: "Show value tooltips")
  attr(:disabled, :boolean, default: false, doc: "Disable the slider")
  attr(:on_slide, :string, default: nil, doc: "Event to push while dragging")
  attr(:on_change, :string, default: nil, doc: "Event to push on release")
  attr(:debounce, :integer, default: 50, doc: "Debounce interval in ms for slide events")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:pips, :any,
    default: nil,
    doc: "Show scale markers. true for defaults, or map with :mode and options"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  def range_slider(assigns) do
    # Determine mode from step type
    float_mode = is_float(assigns.step)

    # Keep values in their native type based on step
    min = ensure_numeric(assigns.min, float_mode)
    max = ensure_numeric(assigns.max, float_mode)
    step = ensure_numeric(assigns.step, float_mode)

    # Calculate default values if not provided (25% and 75% of range)
    range = max - min
    default_min = min + div_or_mult(range, 4, float_mode)
    default_max = max - div_or_mult(range, 4, float_mode)

    # Use provided values or defaults
    value_min =
      if assigns.value_min, do: ensure_numeric(assigns.value_min, float_mode), else: default_min

    value_max =
      if assigns.value_max, do: ensure_numeric(assigns.value_max, float_mode), else: default_max

    # Ensure values are within bounds and snapped to step
    value_min = snap_to_step(clamp(value_min, min, max), step, min, float_mode)
    value_max = snap_to_step(clamp(value_max, min, max), step, min, float_mode)

    # Ensure value_min <= value_max
    value_min = Kernel.min(value_min, value_max)

    id = assigns.id || "range-slider-#{assigns.name}"

    # Calculate percentages for positioning (always float for CSS)
    percent_min = calculate_percent(value_min, min, max)
    percent_max = calculate_percent(value_max, min, max)

    # Format values for display
    format_fn = assigns.format || (&to_string/1)
    display_min = format_fn.(value_min)
    display_max = format_fn.(value_max)

    assigns =
      assigns
      |> assign(:min, min)
      |> assign(:max, max)
      |> assign(:step, step)
      |> assign(:float_mode, float_mode)
      |> assign(:value_min, value_min)
      |> assign(:value_max, value_max)
      |> assign(:display_min, display_min)
      |> assign(:display_max, display_max)
      |> assign(:id, id)
      |> assign(:percent_min, percent_min)
      |> assign(:percent_max, percent_max)
      |> assign(:pips_data, generate_pips(assigns.pips, min, max, step, float_mode))
      |> Map.delete(:pips)

    ~H"""
    <div
      id={@id}
      class={["range-slider", @disabled && "range-slider-disabled", @class]}
      phx-hook=".RangeSlider"
      data-min={@min}
      data-max={@max}
      data-step={@step}
      data-float-mode={@float_mode}
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

      <div :if={@pips_data != []} class="range-slider-pips">
        <div
          :for={pip <- @pips_data}
          class={["range-slider-pip", pip.large && "range-slider-pip-large"]}
          style={"left: #{pip.percent}%"}
        >
          <div class="range-slider-pip-marker"></div>
          <div :if={pip.large} class="range-slider-pip-label">{pip.value}</div>
        </div>
      </div>
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
          this.floatMode = this.el.dataset.floatMode === 'true';
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
          // In integer mode, round to nearest integer to avoid floating point errors
          const rounded = this.floatMode ? steppedValue : Math.round(steppedValue);
          return Math.max(this.min, Math.min(this.max, rounded));
        },

        formatValue(value) {
          return this.floatMode ? value : Math.round(value);
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

          // Update tooltips
          this.updateTooltips();
        },

        updateTooltips() {
          if (!this.tooltips) return;
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);
          const tooltipMin = this.thumbs[0]?.querySelector('.range-slider-tooltip');
          const tooltipMax = this.thumbs[1]?.querySelector('.range-slider-tooltip');
          if (tooltipMin) tooltipMin.textContent = formattedMin;
          if (tooltipMax) tooltipMax.textContent = formattedMax;
        },

        getPayload() {
          const formattedMin = this.formatValue(this.valueMin);
          const formattedMax = this.formatValue(this.valueMax);
          return {
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

  # Clamp value to bounds
  defp clamp(value, min, max) do
    value
    |> Kernel.max(min)
    |> Kernel.min(max)
  end

  # Snap value to nearest step
  defp snap_to_step(value, step, min, true) do
    steps = Float.round((value - min) / step)
    min + steps * step
  end

  defp snap_to_step(value, step, min, false) do
    steps = round((value - min) / step)
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

  # Coerce value to integer or float based on mode
  defp ensure_numeric(value, true) when is_integer(value), do: value * 1.0
  defp ensure_numeric(value, true) when is_float(value), do: value

  defp ensure_numeric(value, true) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp ensure_numeric(value, false) when is_integer(value), do: value
  defp ensure_numeric(value, false) when is_float(value), do: trunc(value)

  defp ensure_numeric(value, false) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp ensure_numeric(_, true), do: 0.0
  defp ensure_numeric(_, false), do: 0

  # Division helper that returns int or float based on mode
  defp div_or_mult(range, divisor, true), do: range / divisor
  defp div_or_mult(range, divisor, false), do: div(range, divisor)

  # Pips generation helpers
  defp generate_pips(nil, _min, _max, _step, _float_mode), do: []

  defp generate_pips(true, min, max, step, float_mode) do
    generate_pips(%{mode: :positions, values: [0, 25, 50, 75, 100]}, min, max, step, float_mode)
  end

  defp generate_pips(%{mode: :positions, values: positions}, min, max, _step, float_mode) do
    range = max - min

    Enum.map(positions, fn percent ->
      value = min + range * percent / 100
      %{percent: percent, value: format_pip_value(value, float_mode), large: true}
    end)
  end

  defp generate_pips(%{mode: :count, count: count}, min, max, _step, float_mode)
       when count > 1 do
    range = max - min

    Enum.map(0..(count - 1), fn i ->
      percent = i * 100 / (count - 1)
      value = min + range * percent / 100
      %{percent: percent, value: format_pip_value(value, float_mode), large: true}
    end)
  end

  defp generate_pips(%{mode: :steps}, min, max, step, float_mode) do
    range = max - min
    step_count = trunc(range / step)

    Enum.map(0..step_count, fn i ->
      value = min + i * step
      percent = (value - min) / range * 100
      # Show label on first, last, and roughly every 5th pip (avoid clutter)
      large = i == 0 or i == step_count or rem(i, max(1, div(step_count, 5))) == 0
      %{percent: percent, value: format_pip_value(value, float_mode), large: large}
    end)
  end

  defp generate_pips(%{mode: :values, values: values}, min, max, _step, float_mode) do
    range = max - min

    Enum.map(values, fn value ->
      percent = (value - min) / range * 100
      %{percent: percent, value: format_pip_value(value, float_mode), large: true}
    end)
  end

  defp generate_pips(_, _min, _max, _step, _float_mode), do: []

  defp format_pip_value(value, true), do: value
  defp format_pip_value(value, false), do: trunc(value)
end

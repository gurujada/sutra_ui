defmodule PhxUI.RangeSlider do
  @moduledoc """
  A dual-handle range slider for selecting a range of values.

  Similar to noUiSlider, this component provides two draggable handles
  to select a minimum and maximum value within a defined range.

  ## Examples

      # Basic range slider
      <.range_slider name="price" min={0} max={1000} value_min={200} value_max={800} />

      # With step increments
      <.range_slider name="age" min={0} max={100} step={5} value_min={20} value_max={60} />

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

  Event payload: `%{name: "field", min: 200, max: 800, field_min: 200, field_max: 800}`

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
  - `step` - Step increment for values (default: 1)
  - `value_min` - Current minimum selected value (default: 25% of range)
  - `value_max` - Current maximum selected value (default: 75% of range)
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
  attr(:min, :integer, default: 0, doc: "Minimum range value")
  attr(:max, :integer, default: 100, doc: "Maximum range value")
  attr(:step, :integer, default: 1, doc: "Step increment")
  attr(:value_min, :integer, default: nil, doc: "Current minimum value")
  attr(:value_max, :integer, default: nil, doc: "Current maximum value")
  attr(:tooltips, :boolean, default: false, doc: "Show value tooltips")
  attr(:disabled, :boolean, default: false, doc: "Disable the slider")
  attr(:on_slide, :string, default: nil, doc: "Event to push while dragging")
  attr(:on_change, :string, default: nil, doc: "Event to push on release")
  attr(:debounce, :integer, default: 50, doc: "Debounce interval in ms for slide events")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  def range_slider(assigns) do
    # Calculate default values if not provided (25% and 75% of range)
    range = assigns.max - assigns.min
    default_min = assigns.min + div(range, 4)
    default_max = assigns.max - div(range, 4)

    # Use || instead of assign_new because attr defaults set keys to nil
    value_min = assigns.value_min || default_min
    value_max = assigns.value_max || default_max
    id = assigns.id || "range-slider-#{assigns.name}"

    assigns =
      assigns
      |> assign(:value_min, value_min)
      |> assign(:value_max, value_max)
      |> assign(:id, id)

    # Ensure value_min <= value_max
    assigns =
      if assigns.value_min > assigns.value_max do
        assign(assigns, :value_min, assigns.value_max)
      else
        assigns
      end

    # Calculate percentages for positioning
    assigns =
      assigns
      |> assign(:percent_min, calculate_percent(assigns.value_min, assigns.min, assigns.max))
      |> assign(:percent_max, calculate_percent(assigns.value_max, assigns.min, assigns.max))

    ~H"""
    <div
      id={@id}
      class={["range-slider", @disabled && "range-slider-disabled", @class]}
      phx-hook=".RangeSlider"
      data-min={@min}
      data-max={@max}
      data-step={@step}
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
          {@value_min}
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
          {@value_max}
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
            const newMin = Math.max(this.min, Math.min(this.valueMax, this.valueMin + delta));
            if (newMin !== this.valueMin) {
              this.valueMin = newMin;
              this.updateUI();
              this.emitChange();
            }
          } else {
            const newMax = Math.max(this.valueMin, Math.min(this.max, this.valueMax + delta));
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
          const steppedValue = Math.round(rawValue / this.step) * this.step;
          return Math.max(this.min, Math.min(this.max, steppedValue));
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

          // Update ARIA attributes
          this.thumbs[0].setAttribute('aria-valuenow', this.valueMin);
          this.thumbs[1].setAttribute('aria-valuenow', this.valueMax);

          // Update hidden inputs
          this.inputs.min.value = this.valueMin;
          this.inputs.max.value = this.valueMax;

          // Update tooltips if present
          if (this.tooltips) {
            const tooltipMin = this.thumbs[0].querySelector('.range-slider-tooltip');
            const tooltipMax = this.thumbs[1].querySelector('.range-slider-tooltip');
            if (tooltipMin) tooltipMin.textContent = this.valueMin;
            if (tooltipMax) tooltipMax.textContent = this.valueMax;
          }
        },

        getPayload() {
          return {
            name: this.name,
            min: this.valueMin,
            max: this.valueMax,
            [`${this.name}_min`]: this.valueMin,
            [`${this.name}_max`]: this.valueMax
          };
        },

        emitSlide() {
          // Dispatch custom event for vanilla JS listeners
          this.el.dispatchEvent(new CustomEvent('phx-ui:range-slide', {
            detail: { min: this.valueMin, max: this.valueMax },
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
          // Dispatch custom event for vanilla JS listeners
          this.el.dispatchEvent(new CustomEvent('phx-ui:range-change', {
            detail: { min: this.valueMin, max: this.valueMax },
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

  defp calculate_percent(value, min, max) do
    range = max - min

    if range == 0 do
      0
    else
      ((value - min) / range * 100)
      |> Float.round(2)
    end
  end
end

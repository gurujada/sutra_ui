defmodule SutraUI.InputOTP do
  @moduledoc """
  One-time password and PIN input with individual digit slots.

  Handles paste distribution, arrow-key navigation, and backspace movement.
  Submits via a hidden aggregate input so it works with Phoenix forms. Emits
  an optional `on_complete` event when all slots are filled.

  ## Examples

      # Simple — 6 digits
      <.input_otp id="verify" name="code" length={6} />

      # Masked PIN
      <.input_otp id="pin" name="pin" length={4} mask placeholder="•" />

      # Grouped with separator
      <.input_otp id="verify" name="code" length={6} groups={[3, 3]}>
        <:separator>—</:separator>
      </.input_otp>

      # Auto-verify when complete
      <.input_otp id="verify" name="code" length={6} on_complete="verify_code" />

  ## Form Integration

  The component renders a hidden `<input name="...">` that aggregates the slot
  values. Use it like any form field:

      <.form for={@form} phx-submit="save">
        <.input_otp id="otp" name={@form[:code].name} value={@form[:code].value}
          length={6} invalid={@form[:code].errors != []} />
      </.form>

  ## Attributes

  * `id` - Required. Unique identifier.
  * `name` - Required. Hidden input name submitted with the form.
  * `value` - Current OTP value. Defaults to `""`.
  * `length` - Number of slots. Defaults to `6`.
  * `groups` - Optional list of group sizes for auto-generated grouped slots.
  * `pattern` - Single-character validation regex. Defaults to `"[0-9]"`.
  * `placeholder` - Slot placeholder.
  * `mask` - Render password-style slots. Defaults to `false`.
  * `disabled` - Disable all slots. Defaults to `false`.
  * `invalid` - Mark slots invalid (adds `aria-invalid`). Defaults to `false`.
  * `on_complete` - LiveView event emitted when all slots are filled.
  * `class` - Additional CSS classes.

  ## Slots

  * `:group` - Optional custom grouping. Use `input_otp_slot/1` inside for full control.
  * `:separator` - Visual separator rendered between groups.

  ## Accessibility

  - Each slot has an `aria-label` ("Digit 1 of 6").
  - `aria-invalid` is set only when `invalid={true}` — not unconditionally.
  - First slot sets `autocomplete="one-time-code"` for SMS autofill.
  - Arrow keys navigate between slots; Backspace moves to the previous slot.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the OTP input")
  attr(:name, :string, required: true, doc: "Hidden input name submitted with the form")
  attr(:value, :string, default: "", doc: "Current OTP value")
  attr(:length, :integer, default: 6, doc: "Number of OTP slots")
  attr(:groups, :list, default: nil, doc: "Optional group sizes for generated slots")
  attr(:pattern, :string, default: "[0-9]", doc: "Single-character validation regex")
  attr(:placeholder, :string, default: nil, doc: "Slot placeholder")
  attr(:mask, :boolean, default: false, doc: "Use password fields")
  attr(:disabled, :boolean, default: false, doc: "Disable all slots")
  attr(:invalid, :boolean, default: false, doc: "Mark slots invalid")

  attr(:on_complete, :string,
    default: nil,
    doc: "LiveView event emitted when all slots are filled"
  )

  attr(:class, :any, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, include: ~w(autocomplete aria-label), doc: "Additional HTML attributes")

  slot(:group, doc: "Custom slot groups")
  slot(:separator, doc: "Visual separator between groups")

  def input_otp(assigns) do
    chars = assigns.value |> to_string() |> String.graphemes()
    type = if assigns.mask, do: "password", else: "text"

    assigns =
      assigns
      |> assign(:chars, chars)
      |> assign(:type, type)
      |> assign(:slot_groups, slot_groups(assigns.length, assigns.groups))

    ~H"""
    <div
      id={@id}
      class={["input-otp", @class]}
      data-pattern={@pattern}
      data-length={@length}
      data-on-complete={@on_complete}
      phx-hook=".InputOTP"
      {@rest}
    >
      <input type="hidden" name={@name} value={@value} data-otp-value />
      <%= if @group != [] do %>
        <%= for {group, idx} <- Enum.with_index(@group) do %>
          <div class="input-otp-group" role="group">
            {render_slot(group)}
          </div>
          <%= if idx < length(@group) - 1 && @separator != [] do %>
            <span class="input-otp-separator" aria-hidden="true">
              {render_slot(Enum.at(@separator, min(idx, length(@separator) - 1)))}
            </span>
          <% end %>
        <% end %>
      <% else %>
        <%= for {group_indexes, group_idx} <- Enum.with_index(@slot_groups) do %>
          <div class="input-otp-group" role="group">
            <%= for index <- group_indexes do %>
              <.input_otp_slot
                id={"#{@id}-#{index}"}
                index={index}
                type={@type}
                value={Enum.at(@chars, index)}
                placeholder={@placeholder}
                disabled={@disabled}
                invalid={@invalid}
                length={@length}
              />
            <% end %>
          </div>
          <%= if group_idx < length(@slot_groups) - 1 && @separator != [] do %>
            <span class="input-otp-separator" aria-hidden="true">
              {render_slot(Enum.at(@separator, min(group_idx, length(@separator) - 1)))}
            </span>
          <% end %>
        <% end %>
      <% end %>
    </div>

    <script :type={ColocatedHook} name=".InputOTP" runtime>
      {
        mounted() {
          this.hidden = this.el.querySelector('[data-otp-value]');
          this.slots = Array.from(this.el.querySelectorAll('[data-otp-slot]'));
          this.pattern = new RegExp(this.el.dataset.pattern || '[0-9]');
          this.onComplete = this.el.dataset.onComplete;
          this.length = Number(this.el.dataset.length || this.slots.length);
          this.lastCompleteValue = null;

          this.slots.forEach((slot, index) => {
            slot.addEventListener('input', (event) => this.handleInput(event, index));
            slot.addEventListener('keydown', (event) => this.handleKeydown(event, index));
            slot.addEventListener('paste', (event) => this.handlePaste(event, index));
          });
        },

        handleInput(event, index) {
          const chars = event.target.value.split('');
          const value = chars.find((c) => this.pattern.test(c)) || '';
          event.target.value = value;
          this.syncHidden();
          if (value && this.slots[index + 1]) { this.slots[index + 1].focus(); this.slots[index + 1].select(); }
          this.maybeComplete();
        },

        handleKeydown(event, index) {
          if (event.key === 'Backspace' && !event.target.value && this.slots[index - 1]) {
            this.slots[index - 1].focus(); this.slots[index - 1].select();
          } else if (event.key === 'ArrowLeft' && this.slots[index - 1]) {
            event.preventDefault(); this.slots[index - 1].focus();
          } else if (event.key === 'ArrowRight' && this.slots[index + 1]) {
            event.preventDefault(); this.slots[index + 1].focus();
          }
        },

        handlePaste(event, index) {
          event.preventDefault();
          const chars = (event.clipboardData || window.clipboardData).getData('text').split('').filter((c) => this.pattern.test(c));
          chars.forEach((c, o) => { if (this.slots[index + o]) this.slots[index + o].value = c; });
          this.syncHidden();
          const next = Math.min(index + chars.length, this.slots.length - 1);
          this.slots[next]?.focus();
          this.maybeComplete();
        },

        syncHidden() {
          this.hidden.value = this.slots.map((s) => s.value).join('');
          this.hidden.dispatchEvent(new Event('input', { bubbles: true }));
          this.hidden.dispatchEvent(new Event('change', { bubbles: true }));
        },

        maybeComplete() {
          if (!this.onComplete) return;
          const value = this.slots.map((s) => s.value).join('');
          if (value.length !== this.length) {
            this.lastCompleteValue = null;
            return;
          }
          if (value !== this.lastCompleteValue) {
            this.lastCompleteValue = value;
            this.pushEvent(this.onComplete, { value: value });
          }
        }
      }
    </script>
    """
  end

  defp slot_groups(length, groups) when is_integer(length) and length > 0 and is_list(groups) do
    indexes = Enum.to_list(0..(length - 1))

    {grouped, remaining} =
      Enum.map_reduce(groups, indexes, fn size, remaining ->
        Enum.split(remaining, max(size, 0))
      end)

    grouped = Enum.reject(grouped, &(&1 == []))

    if remaining == [] do
      grouped
    else
      grouped ++ [remaining]
    end
  end

  defp slot_groups(length, _groups) when is_integer(length) and length > 0 do
    [Enum.to_list(0..(length - 1))]
  end

  defp slot_groups(_length, _groups), do: []

  attr(:index, :integer, required: true, doc: "Zero-based slot index")
  attr(:type, :string, default: "text", doc: "Input type — inherited from parent")
  attr(:value, :string, default: nil, doc: "Current slot value — inherited from parent")
  attr(:placeholder, :string, default: nil, doc: "Slot placeholder — inherited from parent")
  attr(:disabled, :boolean, default: false, doc: "Disabled state — inherited from parent")
  attr(:invalid, :boolean, default: false, doc: "Invalid state — inherited from parent")
  attr(:length, :integer, default: 6, doc: "Total slot count — for aria-label")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a single OTP slot. Use inside a `:group` slot on `input_otp`.

  ## Examples

      <.input_otp_slot index={0} />
      <.input_otp_slot index={1} type="password" placeholder="•" />
  """
  def input_otp_slot(assigns) do
    ~H"""
    <input
      class={["input-otp-slot", @class]}
      type={@type}
      inputmode="numeric"
      autocomplete={if @index == 0, do: "one-time-code", else: "off"}
      maxlength="1"
      value={@value}
      placeholder={@placeholder}
      disabled={@disabled}
      aria-invalid={@invalid && "true"}
      aria-label={"Digit #{@index + 1} of #{@length}"}
      data-otp-slot
      data-index={@index}
      {@rest}
    />
    """
  end
end

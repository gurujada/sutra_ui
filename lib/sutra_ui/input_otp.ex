defmodule SutraUI.InputOTP do
  @moduledoc """
  One-time password and PIN input with individual digit slots.

  Handles paste distribution, arrow-key navigation, and backspace movement.
  Submits via a hidden aggregate input so it works with Phoenix forms.

  ## Examples

      # Simple — 6 digits, auto-grouped
      <.input_otp id="verify" name="code" length={6} />

      # With groups and separator
      <.input_otp id="verify" name="code" length={6}>
        <:group>
          <.input_otp_slot index={0} />
          <.input_otp_slot index={1} />
          <.input_otp_slot index={2} />
        </:group>
        <:separator />
        <:group>
          <.input_otp_slot index={3} />
          <.input_otp_slot index={4} />
          <.input_otp_slot index={5} />
        </:group>
      </.input_otp>

      # Masked PIN
      <.input_otp id="pin" name="pin" length={4} mask placeholder="•" />
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the OTP input")
  attr(:name, :string, required: true, doc: "Hidden input name submitted with the form")
  attr(:value, :string, default: "", doc: "Current OTP value")
  attr(:length, :integer, default: 6, doc: "Number of OTP slots")
  attr(:pattern, :string, default: "[0-9]", doc: "Single-character validation regex")
  attr(:placeholder, :string, default: nil, doc: "Slot placeholder")
  attr(:mask, :boolean, default: false, doc: "Use password fields")
  attr(:disabled, :boolean, default: false, doc: "Disable all slots")
  attr(:invalid, :boolean, default: false, doc: "Mark slots invalid")
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

    ~H"""
    <div
      id={@id}
      class={["input-otp", @class]}
      data-pattern={@pattern}
      data-length={@length}
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
        <div class="input-otp-group" role="group">
          <%= for index <- 0..(@length - 1) do %>
            <input
              id={"#{@id}-#{index}"}
              class="input-otp-slot"
              type={@type}
              inputmode="numeric"
              autocomplete={if index == 0, do: "one-time-code", else: "off"}
              maxlength="1"
              value={Enum.at(@chars, index)}
              placeholder={@placeholder}
              disabled={@disabled}
              aria-invalid={to_attr(@invalid)}
              aria-label={"Digit #{index + 1} of #{@length}"}
              data-otp-slot
              data-index={index}
            />
          <% end %>
        </div>
      <% end %>
    </div>

    <script :type={ColocatedHook} name=".InputOTP" runtime>
      {
        mounted() {
          this.hidden = this.el.querySelector('[data-otp-value]');
          this.slots = Array.from(this.el.querySelectorAll('[data-otp-slot]'));
          this.pattern = new RegExp(this.el.dataset.pattern || '[0-9]');

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
        },

        syncHidden() {
          this.hidden.value = this.slots.map((s) => s.value).join('');
          this.hidden.dispatchEvent(new Event('input', { bubbles: true }));
          this.hidden.dispatchEvent(new Event('change', { bubbles: true }));
        }
      }
    </script>
    """
  end

  attr(:index, :integer, required: true, doc: "Zero-based slot index")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def input_otp_slot(assigns) do
    ~H"""
    <input
      class={["input-otp-slot", @class]}
      type="text"
      inputmode="numeric"
      maxlength="1"
      data-otp-slot
      data-index={@index}
      {@rest}
    />
    """
  end

  defp to_attr(true), do: "true"
  defp to_attr(false), do: "false"
end

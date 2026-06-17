defmodule SutraUI.InputOTP do
  @moduledoc """
  One-time password and PIN input fields.

  Input OTP combines shadcn/ui's group/slot visual model with Preline's PIN
  input behavior: one character per field, paste distribution, arrow-key
  movement, backspace movement, and a hidden aggregate input for Phoenix forms.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the OTP input")
  attr(:name, :string, required: true, doc: "Hidden input name submitted with the form")
  attr(:value, :string, default: "", doc: "Current OTP value")
  attr(:length, :integer, default: 6, doc: "Number of OTP slots")
  attr(:groups, :list, default: nil, doc: "Optional group sizes, for example [3, 3]")
  attr(:pattern, :string, default: "[0-9]", doc: "Single-character validation regex")
  attr(:placeholder, :string, default: nil, doc: "Slot placeholder")
  attr(:mask, :boolean, default: false, doc: "Use password fields")
  attr(:disabled, :boolean, default: false, doc: "Disable all slots")
  attr(:invalid, :boolean, default: false, doc: "Mark slots invalid")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(autocomplete aria-label), doc: "Additional HTML attributes")

  def input_otp(assigns) do
    groups = assigns.groups || [assigns.length]
    chars = assigns.value |> to_string() |> String.graphemes()

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:chars, chars)
      |> assign(:type, if(assigns.mask, do: "password", else: "text"))

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
      <%= for {group_size, group_index} <- Enum.with_index(@groups) do %>
        <div class="input-otp-group" role="group">
          <%= for offset <- 0..(group_size - 1) do %>
            <% index = Enum.sum(Enum.take(@groups, group_index)) + offset %>
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
              aria-invalid={bool_string(@invalid)}
              aria-label={"Digit #{index + 1} of #{@length}"}
              data-otp-slot
              data-index={index}
            />
          <% end %>
        </div>
        <span
          :if={group_index < length(@groups) - 1}
          class="input-otp-separator"
          aria-hidden="true"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <circle cx="12" cy="12" r="1" />
          </svg>
        </span>
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
          const value = chars.find((char) => this.pattern.test(char)) || '';
          event.target.value = value;
          this.syncHidden();

          if (value && this.slots[index + 1]) {
            this.slots[index + 1].focus();
            this.slots[index + 1].select();
          }
        },

        handleKeydown(event, index) {
          if (event.key === 'Backspace' && !event.target.value && this.slots[index - 1]) {
            this.slots[index - 1].focus();
            this.slots[index - 1].select();
          } else if (event.key === 'ArrowLeft' && this.slots[index - 1]) {
            event.preventDefault();
            this.slots[index - 1].focus();
          } else if (event.key === 'ArrowRight' && this.slots[index + 1]) {
            event.preventDefault();
            this.slots[index + 1].focus();
          }
        },

        handlePaste(event, index) {
          event.preventDefault();
          const text = (event.clipboardData || window.clipboardData).getData('text');
          const chars = text.split('').filter((char) => this.pattern.test(char));

          chars.forEach((char, offset) => {
            if (this.slots[index + offset]) {
              this.slots[index + offset].value = char;
            }
          });

          this.syncHidden();
          const next = Math.min(index + chars.length, this.slots.length - 1);
          this.slots[next]?.focus();
        },

        syncHidden() {
          this.hidden.value = this.slots.map((slot) => slot.value).join('');
          this.hidden.dispatchEvent(new Event('input', { bubbles: true }));
          this.hidden.dispatchEvent(new Event('change', { bubbles: true }));
        }
      }
    </script>
    """
  end

  defp bool_string(true), do: "true"
  defp bool_string(false), do: "false"
end

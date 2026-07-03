defmodule SutraUI.Response do
  @moduledoc """
  Renders model responses as plain text or streamed Markdown.

  Response is intentionally small: it handles the response surface and, when
  `format="markdown"`, uses MDEx to render sanitized Markdown. It does not own
  chat state, provider callbacks, or streaming transport. The parent LiveView
  passes the current text as it changes.

  ## Examples

      <.response value={@answer} />

      <.response id="answer" value={@answer} streaming reveal="word" />

      <.response value={@streamed_markdown} format="markdown" streaming />

      <.response>
        <p>Custom rendered content.</p>
      </.response>

  ## Attributes

  * `value` - Response text or Markdown. Defaults to `nil`.
  * `format` - One of `text` or `markdown`. Defaults to `text`.
  * `streaming` - Marks the response as incomplete. The parent LiveView owns this state.
  * `reveal` - One of `chunk`, `word`, `character`, or `line`. Defaults to `chunk`.
  * `sanitize` - Sanitizes Markdown HTML output. Defaults to `true`.
  * `mdex_options` - Extra MDEx options passed to the renderer.
  * `class` - Additional CSS classes.

  Animated reveal modes (`word`, `character`, `line`) require an `id` because
  Phoenix LiveView hooks need a stable DOM id. They smooth already-received
  text in the browser; the parent LiveView still owns provider streaming.
  Markdown always renders by chunk so partial Markdown can stay valid and
  sanitized.

  ## Accessibility

  - When `streaming` is true, the root sets `aria-live="polite"` unless you
    pass your own `aria-live` value, and `aria-busy="true"` unless you pass
    your own value.
  - Markdown output is sanitized by default before being marked as safe HTML.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @animated_reveals ~w(character word line)

  attr(:id, :string,
    default: nil,
    doc: "Stable DOM id. Required for animated reveal modes."
  )

  attr(:value, :string, default: nil, doc: "Response text or Markdown")

  attr(:format, :string,
    default: "text",
    values: ~w(text markdown),
    doc: "Response format"
  )

  attr(:streaming, :boolean,
    default: false,
    doc: "Enables MDEx streaming mode for incomplete Markdown"
  )

  attr(:reveal, :string,
    default: "chunk",
    values: ~w(chunk word character line),
    doc: "How newly received text appears"
  )

  attr(:sanitize, :boolean,
    default: true,
    doc: "Sanitize Markdown HTML output"
  )

  attr(:mdex_options, :any,
    default: [],
    doc: "Additional MDEx options"
  )

  attr(:class, :any, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(role aria-label aria-labelledby aria-live aria-busy),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, doc: "Optional custom response content")

  def response(assigns) do
    assigns =
      assigns
      |> assign(:rest, response_attrs(assigns.rest, assigns.streaming))
      |> assign(:streaming_attr, if(assigns.streaming, do: "true"))
      |> assign(:hook, response_hook(assigns))
      |> assign(:markdown_html, markdown_html(assigns))

    ~H"""
    <div
      id={@id}
      class={["response", @class]}
      data-format={@format}
      data-reveal={@reveal}
      data-streaming={@streaming_attr}
      phx-hook={@hook}
      {@rest}
    >
      <div :if={@format == "markdown" and @value != nil} class="response-markdown">
        {Phoenix.HTML.raw(@markdown_html)}
      </div>
      <span :if={@format == "text" and @value != nil} class="response-text" data-response-content>{@value}</span>
      <div :if={@value == nil and @inner_block != []} class="response-content">
        {render_slot(@inner_block)}
      </div>
      <span :if={@streaming} class="response-cursor" aria-hidden="true"></span>
    </div>

    <script :type={ColocatedHook} name=".Response">
      export default {
        mounted() {
          this.visibleText = "";
          this.queue = "";
          this.timer = null;
          this.sync({ initial: true });
        },

        updated() {
          this.sync();
        },

        destroyed() {
          this.stop();
        },

        sync(options = {}) {
          const target = this.el.querySelector("[data-response-content]");
          if (!target) return;

          const reveal = this.el.dataset.reveal || "chunk";
          const streaming = this.el.dataset.streaming === "true";
          const nextText = target.textContent || "";
          const canReveal = this.canReveal(reveal);

          if (!canReveal || (options.initial && !streaming)) {
            this.stop();
            this.visibleText = nextText;
            this.queue = "";
            target.textContent = nextText;
            return;
          }

          if (nextText.startsWith(this.visibleText)) {
            this.queue = nextText.slice(this.visibleText.length);
          } else {
            this.visibleText = "";
            this.queue = nextText;
          }

          target.textContent = this.visibleText;
          this.play();
        },

        canReveal(reveal) {
          if (!["character", "word", "line"].includes(reveal)) return false;
          return !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
        },

        play() {
          if (this.timer) return;

          const tick = () => {
            const target = this.el.querySelector("[data-response-content]");
            if (!target || !this.queue) {
              this.stop();
              return;
            }

            const reveal = this.el.dataset.reveal || "chunk";
            const unit = this.takeUnit(this.queue, reveal);

            this.visibleText += unit;
            this.queue = this.queue.slice(unit.length);
            target.textContent = this.visibleText;

            this.timer = window.setTimeout(tick, this.delayFor(reveal));
          };

          this.timer = window.setTimeout(tick, 0);
        },

        stop() {
          if (this.timer) {
            window.clearTimeout(this.timer);
            this.timer = null;
          }
        },

        takeUnit(text, reveal) {
          if (reveal === "character") {
            return Array.from(text)[0] || "";
          }

          if (reveal === "line") {
            const index = text.indexOf("\n");
            return index === -1 ? text : text.slice(0, index + 1);
          }

          const match = text.match(/^(\s*\S+\s*)/);
          return match ? match[0] : text;
        },

        delayFor(reveal) {
          if (reveal === "character") return 18;
          if (reveal === "line") return 120;
          return 70;
        }
      }
    </script>
    """
  end

  defp response_attrs(rest, true) do
    rest
    |> Map.put_new(:"aria-live", "polite")
    |> Map.put_new(:"aria-busy", "true")
  end

  defp response_attrs(rest, false), do: rest

  defp response_hook(%{format: "text", reveal: reveal, id: id})
       when reveal in @animated_reveals and is_binary(id) and id != "" do
    "SutraUI.Response.Response"
  end

  defp response_hook(_assigns), do: nil

  defp markdown_html(%{format: "markdown", value: value} = assigns) when is_binary(value) do
    options =
      assigns.mdex_options
      |> normalize_options()
      |> Keyword.put(:streaming, assigns.streaming)
      |> put_sanitize(assigns.sanitize)

    MDEx.new(options)
    |> MDEx.Document.put_markdown(value)
    |> MDEx.to_html!()
  end

  defp markdown_html(_assigns), do: nil

  defp normalize_options(options) when is_map(options), do: Enum.into(options, [])
  defp normalize_options(options) when is_list(options), do: options
  defp normalize_options(_options), do: []

  defp put_sanitize(options, true) do
    Keyword.put_new(options, :sanitize, MDEx.Document.default_sanitize_options())
  end

  defp put_sanitize(options, false) do
    options
    |> Keyword.put(:sanitize, nil)
    |> Keyword.put_new(:render, unsafe: true)
  end
end

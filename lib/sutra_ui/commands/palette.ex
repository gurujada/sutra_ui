defmodule SutraUI.Commands.Palette do
  @moduledoc """
  The command palette: a dialog with a search box and a list of actions, opened with a
  shortcut (`mod+k` by default) or a button.

  It is built on the div-based `SutraUI.Dialog` (so it shows in a screen share) with the look
  of `SutraUI.Command`. The server renders the shell and the actions as JSON; the browser
  module (`sutra_ui/commands`, bundled by your esbuild like `dialog`) renders the list,
  filters it, and handles keys, shortcuts, pages, arguments and recent actions.

      <.command_palette id="command-palette" commands={@sutra_commands} />
      <.button phx-click={show_palette("command-palette")}>Search</.button>

  Without `SutraUI.Commands.Live` (a static list of actions that need no server):

      <.command_palette id="palette" actions={[Action.new(id: "home", title: "Home", navigate: "/")]} />

  ## Keys

  | Key | Does |
  |-----|------|
  | `mod+k` (the `shortcut` attribute) | Opens, or closes when open. Works while typing |
  | Arrow up / down | Moves through the list |
  | Enter | Runs the active action (or opens its page, or asks for its next argument) |
  | Arrow right (caret at the end) | Opens the active result's own actions |
  | Backspace on an empty box | Back one page |
  | Escape | Back one page or step; at the first page, closes |
  | `?` | Opens the list of keyboard shortcuts (not while typing) |
  | An action's `shortcut` | Runs it from anywhere (not while typing in a field, unless it uses Ctrl, Cmd or Alt) |

  Focus returns to what had it when the palette closes.

  ## Accessibility

  The search box is a `combobox` controlling a `listbox` of `option`s (grouped, with
  `aria-activedescendant`); disabled actions are `aria-disabled` and say why; the number of
  results is announced in a polite live region.
  """

  use Phoenix.Component

  alias SutraUI.Commands
  alias SutraUI.Commands.Action

  attr(:id, :string, required: true, doc: "Unique id; the dialog is `\"\#{id}-dialog\"`")

  attr(:commands, :map,
    default: nil,
    doc: "`@sutra_commands`, assigned by `SutraUI.Commands.Live`"
  )

  attr(:actions, :list, default: [], doc: "Actions for a palette without `SutraUI.Commands.Live`")

  attr(:sources, :list,
    default: [],
    doc: "`{id, heading}` server searches for a palette without `SutraUI.Commands.Live`"
  )

  attr(:shortcut, :string,
    default: "mod+k",
    doc: "Opens the palette; a chord (`mod+k`) or sequence (`g k`)"
  )

  attr(:placeholder, :string,
    default: "Type a command or search...",
    doc: "Search box placeholder"
  )

  attr(:empty_text, :string, default: "No results found.", doc: "Shown when nothing matches")
  attr(:label, :string, default: "Command palette", doc: "Accessible name of the dialog")
  attr(:show, :boolean, default: false, doc: "Render the palette open")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the panel")
  attr(:rest, :global, doc: "Additional HTML attributes for the root")

  def command_palette(assigns) do
    {actions, sources} =
      case assigns.commands do
        nil -> {Enum.map(assigns.actions, &Action.new/1), assigns.sources}
        commands -> {Commands.visible(commands), commands.sources}
      end

    assigns =
      assigns
      |> assign(:visible, actions)
      |> assign(:wire, Phoenix.json_library().encode!(Enum.map(actions, &Action.to_wire/1)))
      |> assign(
        :wire_sources,
        Phoenix.json_library().encode!(
          for {id, title} <- sources, do: %{id: to_string(id), title: title}
        )
      )
      |> assign(:state, if(assigns.show, do: "open", else: "closed"))

    ~H"""
    <div
      id={@id}
      phx-hook=".CommandPalette"
      data-actions={@wire}
      data-sources={@wire_sources}
      data-shortcut={@shortcut}
      data-empty-text={@empty_text}
      {@rest}
    >
      <div id={"#{@id}-shell"} phx-update="ignore">
        <SutraUI.Dialog.dialog
          id={"#{@id}-dialog"}
          show={@show}
          class={Enum.join(["command-palette", @class], " ")}
        >
          <div class="command" data-command-palette data-state={@state}>
            <header>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />
              </svg>
              <input
                type="text"
                role="combobox"
                aria-label={@label}
                aria-expanded="true"
                aria-controls={"#{@id}-list"}
                aria-autocomplete="list"
                aria-haspopup="listbox"
                placeholder={@placeholder}
                autocomplete="off"
                autocorrect="off"
                spellcheck="false"
              />
            </header>
            <nav data-palette-trail aria-label="Where you are" hidden></nav>
            <div
              id={"#{@id}-list"}
              role="listbox"
              aria-label="Commands"
              data-empty={if @visible == [], do: "empty", else: "list"}
              data-empty-text={@empty_text}
            >
              <.initial_rows id={@id} actions={@visible} />
            </div>
            <p data-palette-hint hidden></p>
            <div data-palette-confirm hidden></div>
            <p role="status" aria-live="polite" class="sr-only"></p>
          </div>
        </SutraUI.Dialog.dialog>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CommandPalette">
      import {CommandPalette} from "sutra_ui/commands"
      export default CommandPalette
    </script>
    """
  end

  # The list as the server first draws it; the browser module takes it over on mount.
  attr(:id, :string, required: true)
  attr(:actions, :list, required: true)

  defp initial_rows(assigns) do
    assigns =
      assign(
        assigns,
        :groups,
        assigns.actions
        |> Enum.with_index()
        |> Enum.chunk_by(fn {action, _} -> action.section end)
      )

    ~H"""
    <%= for group <- @groups do %>
      <% section = elem(hd(group), 0).section %>
      <div :if={section} role="group" aria-labelledby={"#{@id}-h-#{elem(hd(group), 1)}"}>
        <div id={"#{@id}-h-#{elem(hd(group), 1)}"} class="command-palette-heading" role="presentation">
          {section}
        </div>
        <.option :for={{action, index} <- group} id={@id} action={action} index={index} />
      </div>
      <.option :for={{action, index} <- group} :if={!section} id={@id} action={action} index={index} />
    <% end %>
    """
  end

  attr(:id, :string, required: true)
  attr(:action, :any, required: true)
  attr(:index, :integer, required: true)

  defp option(assigns) do
    ~H"""
    <div
      id={"#{@id}-opt-#{@index}"}
      role="option"
      data-index={@index}
      data-action-id={@action.id}
      data-state={if @action.disabled, do: "disabled", else: "idle"}
      data-tone={@action.tone}
      aria-selected="false"
      aria-disabled={@action.disabled && "true"}
    >
      <span :if={@action.icon} class={["command-palette-icon", @action.icon]} aria-hidden="true"></span>
      <span class="command-palette-title">
        <span>{@action.title}</span>
        <span :if={is_binary(@action.disabled)} class="command-palette-reason">{@action.disabled}</span>
      </span>
      <span :if={@action.badge} class="command-palette-badge">{@action.badge}</span>
      <span :if={@action.shortcut} class="command-palette-keys" aria-hidden="true">
        <kbd :for={cap <- shortcut_caps(@action.shortcut)}>{cap}</kbd>
      </span>
      <span :if={@action.children != []} class="command-palette-more" aria-hidden="true">›</span>
    </div>
    """
  end

  # "mod+k" and "g h" as key caps for the server's first draw ("Ctrl" until the browser knows).
  defp shortcut_caps(spec) do
    spec
    |> String.split(" ", trim: true)
    |> Enum.flat_map(fn chord ->
      chord
      |> String.split(~r/\+(?=.)/)
      |> Enum.map(fn
        "mod" -> "Ctrl"
        "ctrl" -> "Ctrl"
        "alt" -> "Alt"
        "shift" -> "Shift"
        "meta" -> "Win"
        key -> String.upcase(key)
      end)
    end)
  end

  @doc """
  Opens the palette with the given id.

      <.button phx-click={show_palette("command-palette")}>Search</.button>
  """
  def show_palette(js \\ %Phoenix.LiveView.JS{}, id) when is_binary(id) do
    SutraUI.Dialog.show_dialog(js, "#{id}-dialog")
  end

  @doc "Closes the palette with the given id."
  def hide_palette(js \\ %Phoenix.LiveView.JS{}, id) when is_binary(id) do
    SutraUI.Dialog.hide_dialog(js, "#{id}-dialog")
  end
end

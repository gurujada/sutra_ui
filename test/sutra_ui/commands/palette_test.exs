defmodule SutraUI.Commands.PaletteTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias SutraUI.Commands.Action
  alias SutraUI.Commands.Palette

  defp render_palette(assigns) do
    render_component(&Palette.command_palette/1, Map.put(assigns, :id, "pal"))
  end

  defp doc(html), do: LazyHTML.from_fragment(html)

  defp attr(html, selector, name),
    do: html |> doc() |> LazyHTML.query(selector) |> LazyHTML.attribute(name)

  defp text(html, selector), do: html |> doc() |> LazyHTML.query(selector) |> LazyHTML.text()

  defp actions do
    [
      Action.new(id: "home", title: "Go home", section: "Go to", shortcut: "g h", navigate: "/"),
      Action.new(id: "settings", title: "Settings", section: "Go to", patch: "/s"),
      Action.new(
        id: "delete",
        title: "Delete everything",
        section: "Danger",
        tone: :danger,
        run: fn s, _ -> s end
      ),
      Action.new(
        id: "publish",
        title: "Publish",
        section: "Danger",
        disabled: "Add a title first",
        run: fn s, _ -> s end
      ),
      Action.new(
        id: "more",
        title: "More",
        children: [Action.new(id: "m1", title: "Copy", copy: "x")]
      )
    ]
  end

  describe "closed (default)" do
    setup do
      %{html: render_palette(%{actions: actions()})}
    end

    test "is a div-based dialog that is not open", %{html: html} do
      refute html =~ "<dialog"
      assert attr(html, "[role=dialog]", "aria-modal") == ["true"]
      assert attr(html, "[data-command-palette]", "data-state") == ["closed"]
      refute html =~ "is-open"
    end

    test "the search box is a combobox that controls the listbox", %{html: html} do
      assert attr(html, "input", "role") == ["combobox"]
      assert attr(html, "input", "aria-label") == ["Command palette"]
      assert attr(html, "input", "aria-autocomplete") == ["list"]
      assert attr(html, "input", "aria-controls") == ["pal-list"]
      assert attr(html, "[role=listbox]", "id") == ["pal-list"]
      assert attr(html, "[role=listbox]", "aria-label") == ["Commands"]
    end

    test "announces results in a polite live region", %{html: html} do
      assert attr(html, "[role=status]", "aria-live") == ["polite"]
    end

    test "groups actions under their section heading", %{html: html} do
      assert attr(html, "[role=group]", "aria-labelledby") == ["pal-h-0", "pal-h-2"]
      assert text(html, "#pal-h-0") =~ "Go to"
      assert text(html, "#pal-h-2") =~ "Danger"
    end

    test "every action is an option with its title as its name", %{html: html} do
      assert html |> doc() |> LazyHTML.query("[role=option]") |> Enum.count() == 5
      assert text(html, "#pal-opt-0") =~ "Go home"
      assert attr(html, "[role=option]", "aria-selected") |> Enum.uniq() == ["false"]
    end

    test "a disabled action says why and is aria-disabled", %{html: html} do
      assert attr(html, "#pal-opt-3", "aria-disabled") == ["true"]
      assert attr(html, "#pal-opt-3", "data-state") == ["disabled"]
      assert text(html, "#pal-opt-3") =~ "Add a title first"
      assert attr(html, "#pal-opt-0", "aria-disabled") == []
      assert attr(html, "#pal-opt-0", "data-state") == ["idle"]
    end

    test "a danger action has the danger tone", %{html: html} do
      assert attr(html, "#pal-opt-2", "data-tone") == ["danger"]
    end

    test "a shortcut shows key caps hidden from screen readers", %{html: html} do
      assert attr(html, "#pal-opt-0 .command-palette-keys", "aria-hidden") == ["true"]
      assert text(html, "#pal-opt-0 kbd") =~ "G"
    end

    test "an action with children shows a chevron hidden from screen readers", %{html: html} do
      assert attr(html, "#pal-opt-4 .command-palette-more", "aria-hidden") == ["true"]
    end

    test "carries the actions as JSON for the browser module", %{html: html} do
      [json] = attr(html, "#pal", "data-actions")
      decoded = Phoenix.json_library().decode!(json)

      assert Enum.map(decoded, & &1["id"]) == ~w(home settings delete publish more)
      assert Enum.at(decoded, 3)["disabled"] == "Add a title first"
      refute json =~ "#Function"
    end

    test "extracted hook, no inline script, no style attribute", %{html: html} do
      assert attr(html, "#pal", "phx-hook") == ["SutraUI.Commands.Palette.CommandPalette"]
      refute html =~ ~r/<script[^>]*>[^<]*(?:mounted|addEventListener)/
      refute html =~ ~r/\sstyle=/
    end

    test "the list is not patched by the server after mount", %{html: html} do
      assert attr(html, "#pal-shell", "phx-update") == ["ignore"]
    end
  end

  describe "open" do
    test "renders open with the dialog open" do
      html = render_palette(%{actions: actions(), show: true})

      assert attr(html, "[data-command-palette]", "data-state") == ["open"]
      assert html =~ "is-open"
    end
  end

  describe "empty" do
    test "without actions the list is marked empty with the text to show" do
      html = render_palette(%{actions: [], empty_text: "Nothing to do"})

      assert attr(html, "[role=listbox]", "data-empty") == ["empty"]
      assert attr(html, "[role=listbox]", "data-empty-text") == ["Nothing to do"]
      assert html |> doc() |> LazyHTML.query("[role=option]") |> Enum.count() == 0
    end
  end

  describe "options" do
    test "shortcut, sources, placeholder and label are configurable" do
      html =
        render_palette(%{
          actions: actions(),
          shortcut: "mod+j",
          sources: [workbooks: "Workbooks"],
          placeholder: "Find anything",
          label: "Jump to"
        })

      assert attr(html, "#pal", "data-shortcut") == ["mod+j"]
      assert attr(html, "input", "placeholder") == ["Find anything"]
      assert attr(html, "input", "aria-label") == ["Jump to"]
      [json] = attr(html, "#pal", "data-sources")

      assert Phoenix.json_library().decode!(json) == [
               %{"id" => "workbooks", "title" => "Workbooks"}
             ]
    end

    test "page actions come first and an id appears once" do
      commands = %{
        actions: [
          Action.new(id: "a", title: "A", copy: "1"),
          Action.new(id: "b", title: "B", copy: "2")
        ],
        page_actions: [Action.new(id: "b", title: "B page", copy: "3")],
        sources: []
      }

      html = render_palette(%{commands: commands})
      [json] = attr(html, "#pal", "data-actions")

      assert json |> Phoenix.json_library().decode!() |> Enum.map(& &1["title"]) == [
               "B page",
               "A"
             ]
    end
  end

  describe "show_palette/2 and hide_palette/2" do
    test "target the palette's dialog" do
      assert %Phoenix.LiveView.JS{
               ops: [["dispatch", %{event: "phx:show-dialog", to: "#pal-dialog"}]]
             } =
               Palette.show_palette("pal")

      assert %Phoenix.LiveView.JS{
               ops: [["dispatch", %{event: "phx:hide-dialog", to: "#pal-dialog"}]]
             } =
               Palette.hide_palette("pal")
    end
  end
end

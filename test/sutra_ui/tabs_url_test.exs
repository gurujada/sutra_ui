defmodule SutraUI.TabsURLTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import SutraUI.HTMLHelpers

  alias SutraUI.Tabs

  @endpoint SutraUI.TabsLive.Endpoint

  defp tabs_html(extra \\ %{}) do
    assigns = Map.merge(%{value: "overview", keep: false}, extra)

    rendered_to_string(~H"""
    <Tabs.tabs id="t" value={@value} keep={@keep} label="Sections">
      <:tab value="overview" patch="/tabs/overview">Overview</:tab>
      <:tab value="notes" patch="/tabs/notes">Notes</:tab>
      <:tab value="files" patch="/tabs/files">Files</:tab>
      <:panel value="overview">Overview body</:panel>
      <:panel value="notes">Notes body</:panel>
      <:panel value="files">Files body</:panel>
    </Tabs.tabs>
    """)
  end

  describe "patch tabs (render)" do
    test "tabs are links with tab roles, the active one selected" do
      html = tabs_html()

      assert attribute(html, "[role=tablist]", "aria-label") == "Sections"
      assert attribute(html, "a#t-tab-overview", "href") == "/tabs/overview"
      assert attribute(html, "a#t-tab-overview", "data-phx-link") == "patch"
      assert attribute(html, "a#t-tab-overview", "role") == "tab"
      assert attribute(html, "#t-tab-overview", "aria-selected") == "true"
      assert attribute(html, "#t-tab-overview", "data-state") == "active"
      assert attribute(html, "#t-tab-overview", "tabindex") == "0"
      assert attribute(html, "#t-tab-notes", "aria-selected") == "false"
      assert attribute(html, "#t-tab-notes", "data-state") == "inactive"
      assert attribute(html, "#t-tab-notes", "tabindex") == "-1"
      assert text(html, "#t-tab-notes") == "Notes"
      assert attribute(html, "#t", "data-mode") == "patch"
      assert attribute(html, "#t", "data-activation") == "manual"
    end

    test "each tab has a click command that switches on the client before the patch" do
      html = tabs_html()
      click = attribute(html, "#t-tab-notes", "phx-click")
      assert click =~ "aria-selected"
      assert click =~ "#t-panel-notes"
      assert click =~ "hidden"
    end

    test "by default only the active panel is rendered; the others are empty with a loading state" do
      html = tabs_html(%{value: "notes"})

      assert text(html, "#t-panel-notes") == "Notes body"
      assert attribute(html, "#t-panel-notes", "role") == "tabpanel"
      assert attribute(html, "#t-panel-notes", "aria-labelledby") == "t-tab-notes"
      assert attribute(html, "#t-panel-notes", "hidden") == nil
      assert attribute(html, "#t-panel-notes", "data-empty") == nil

      for other <- ~w(overview files) do
        assert attribute(html, "#t-panel-#{other}", "hidden") == ""
        assert attribute(html, "#t-panel-#{other}", "data-empty") == ""
        assert text(html, "#t-panel-#{other} [role=status]") == "Loading"
      end

      refute html =~ "Overview body"
      refute html =~ "Files body"
    end

    test "keep with a list renders the visited panels hidden" do
      html = tabs_html(%{value: "notes", keep: ["overview", "notes"]})

      assert text(html, "#t-panel-overview") == "Overview body"
      assert attribute(html, "#t-panel-overview", "hidden") == ""
      assert attribute(html, "#t-panel-overview", "data-empty") == nil
      assert attribute(html, "#t-panel-files", "data-empty") == ""
    end

    test "keep true renders every given panel" do
      html = tabs_html(%{value: "overview", keep: true})
      assert text(html, "#t-panel-notes") == "Notes body"
      assert text(html, "#t-panel-files") == "Files body"
      assert attribute(html, "#t-panel-files", "hidden") == ""
    end

    test "a panel slot may be left out: the tab has an empty panel with a loading state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" value="a" loading_label="Loading…">
          <:tab value="a" patch="/a">A</:tab>
          <:tab value="b" patch="/b">B</:tab>
          <:panel value="a">A body</:panel>
        </Tabs.tabs>
        """)

      assert attribute(html, "#t-panel-b", "data-empty") == ""
      assert text(html, "#t-panel-b [role=status]") == "Loading…"
    end

    test "visit/2 adds a value once, in order" do
      assert Tabs.visit([], "a") == ["a"]
      assert Tabs.visit(["a"], "b") == ["a", "b"]
      assert Tabs.visit(["a", "b"], "a") == ["a", "b"]
    end

    test "patch tabs need value" do
      assigns = %{}

      assert_raise ArgumentError, ~r/needs `value`/, fn ->
        rendered_to_string(~H"""
        <Tabs.tabs id="t">
          <:tab value="a" patch="/a">A</:tab>
        </Tabs.tabs>
        """)
      end
    end

    test "a disabled tab is disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="t" value="a">
          <:tab value="a" patch="/a">A</:tab>
          <:tab value="b" patch="/b" disabled>B</:tab>
          <:panel value="a">x</:panel>
        </Tabs.tabs>
        """)

      assert attribute(html, "#t-tab-b", "disabled") == ""
    end
  end

  describe "client-only tabs keep working" do
    test "buttons, default_value, every panel rendered" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="c" default_value="two">
          <:tab value="one">One</:tab>
          <:tab value="two">Two</:tab>
          <:panel value="one">One body</:panel>
          <:panel value="two">Two body</:panel>
        </Tabs.tabs>
        """)

      assert attribute(html, "#c", "data-mode") == "client"
      assert attribute(html, "#c", "data-activation") == "automatic"
      assert attribute(html, "button#c-tab-two", "role") == "tab"
      assert attribute(html, "#c-tab-two", "aria-selected") == "true"
      assert attribute(html, "#c-tab-two", "data-state") == "active"
      assert text(html, "#c-panel-one") == "One body"
      assert attribute(html, "#c-panel-one", "hidden") == ""
      assert attribute(html, "#c-panel-two", "hidden") == nil
      assert attribute(html, "#c-panel-one", "data-empty") == nil
    end

    test "needs default_value or value" do
      assigns = %{}

      assert_raise ArgumentError, ~r/default_value/, fn ->
        rendered_to_string(~H"""
        <Tabs.tabs id="c">
          <:tab value="a">A</:tab><:panel value="a">x</:panel>
        </Tabs.tabs>
        """)
      end
    end
  end

  describe "navigate tabs (render)" do
    test "a nav landmark of links, the active one aria-current, no tab roles or panels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="n" value="billing" label="Account">
          <:tab value="profile" navigate="/account/profile">Profile</:tab>
          <:tab value="billing" navigate="/account/billing">Billing</:tab>
        </Tabs.tabs>
        """)

      assert attribute(html, "nav#n", "aria-label") == "Account"
      assert attribute(html, "#n-tab-billing", "aria-current") == "page"
      assert attribute(html, "#n-tab-profile", "aria-current") == nil
      assert attribute(html, "#n-tab-billing", "data-state") == "active"
      assert attribute(html, "#n-tab-profile", "data-state") == "inactive"
      assert attribute(html, "#n-tab-profile", "href") == "/account/profile"
      assert attribute(html, "#n-tab-profile", "data-phx-link") == "redirect"
      assert count(html, "[role=tab]") == 0
      assert count(html, "[role=tablist]") == 0
      assert count(html, "[role=tabpanel]") == 0
      assert text(html, "#n-tab-billing") == "Billing"
    end
  end

  describe "tabs as routes of one LiveView" do
    test "a direct URL renders the right tab, active in the markup" do
      {:ok, view, html} = live(build_conn(), "/tabs/notes")

      assert attribute(html, "#t-tab-notes", "aria-selected") == "true"
      assert attribute(html, "#t-panel-notes", "hidden") == nil
      assert count(html, "#t-panel-notes input[name=draft]") == 1
      assert attribute(html, "#t-panel-overview", "data-empty") == ""
      assert render(view) =~ "params=1"
    end

    test "clicking a tab patches: handle_params runs, the URL changes, no remount" do
      {:ok, view, _html} = live(build_conn(), "/tabs/overview")
      pid_before = text(render(view), "#pid")
      assert text(render(view), "#counters") == "mounts=1 params=1"

      html = view |> element("#t-tab-notes") |> render_click()
      assert_patch(view, "/tabs/notes")

      assert text(html, "#counters") == "mounts=1 params=2"
      assert text(html, "#pid") == pid_before
      assert attribute(html, "#t-tab-notes", "aria-selected") == "true"
      assert attribute(html, "#t-tab-overview", "aria-selected") == "false"
      assert attribute(html, "#t-panel-overview", "hidden") == ""
      assert attribute(html, "#t-panel-notes", "hidden") == nil
    end

    test "without keep a left panel is emptied" do
      {:ok, view, _} = live(build_conn(), "/tabs/overview")
      html = view |> element("#t-tab-notes") |> render_click()
      refute html =~ "Overview content"
      assert attribute(html, "#t-panel-overview", "data-empty") == ""
    end

    test "keep preserves a typed draft across switches" do
      {:ok, view, _} = live(build_conn(), "/tabs/notes?keep=1")

      view |> form("#draft-form", %{draft: "half a sentence"}) |> render_change()

      html = view |> element("#t-tab-overview") |> render_click()
      assert_patch(view, "/tabs/overview?keep=1")

      # The notes panel is still on the page, hidden, with the draft in it.
      assert attribute(html, "#t-panel-notes", "hidden") == ""
      assert attribute(html, "#t-panel-notes", "data-empty") == nil
      assert attribute(html, "#t-panel-notes input", "value") == "half a sentence"

      html = view |> element("#t-tab-notes") |> render_click()
      assert attribute(html, "#t-panel-notes", "hidden") == nil
      assert attribute(html, "#t-panel-notes input", "value") == "half a sentence"
      assert text(html, "#counters") == "mounts=1 params=3"
    end

    test "keep renders only visited panels, not every panel" do
      {:ok, _view, html} = live(build_conn(), "/tabs/overview?keep=1")
      assert attribute(html, "#t-panel-notes", "data-empty") == ""
    end
  end

  describe "navigate tabs across LiveViews of one live_session" do
    test "the bar marks the page's tab and a click redirects to the other LiveView" do
      {:ok, view, html} = live(build_conn(), "/account/profile")
      assert attribute(html, "#n-tab-profile", "aria-current") == "page"

      assert {:ok, view, html} =
               view
               |> element("#n-tab-billing")
               |> render_click()
               |> follow_redirect(build_conn())

      assert attribute(html, "#n-tab-billing", "aria-current") == "page"
      assert text(render(view), "#page") == "billing"
    end
  end

  describe "filter_tabs share the link handling" do
    test "patch and navigate items are links, others buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.filter_tabs id="f" label="Filter">
          <:item label="All" active patch="/x" />
          <:item label="Mine" navigate="/y" />
          <:item label="Waiting" click="w" value="waiting" />
        </Tabs.filter_tabs>
        """)

      assert attribute(html, "a[href='/x']", "data-phx-link") == "patch"
      assert attribute(html, "a[href='/x']", "aria-current") == "page"
      assert attribute(html, "a[href='/y']", "data-phx-link") == "redirect"
      assert attribute(html, "button", "aria-pressed") == "false"
    end
  end
end

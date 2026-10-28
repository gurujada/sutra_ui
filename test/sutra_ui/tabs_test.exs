defmodule SutraUI.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Tabs

  describe "tabs/1 rendering" do
    test "renders tabs container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(class="tabs)
    end

    test "renders tabs list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ "tabs-list"
      assert html =~ ~s(role="tablist")
    end

    test "renders tab triggers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Account</:tab>
          <:tab value="tab2">Password</:tab>
          <:panel value="tab1">Account content</:panel>
          <:panel value="tab2">Password content</:panel>
        </Tabs.tabs>
        """)

      assert html =~ "tabs-trigger"
      assert html =~ "Account"
      assert html =~ "Password"
    end

    test "renders tab panels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Content for tab 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ "tabs-panel"
      assert html =~ "Content for tab 1"
    end
  end

  describe "tabs/1 default value" do
    test "marks default tab as active" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab2">
          <:tab value="tab1">Tab 1</:tab>
          <:tab value="tab2">Tab 2</:tab>
          <:panel value="tab1">Panel 1</:panel>
          <:panel value="tab2">Panel 2</:panel>
        </Tabs.tabs>
        """)

      # The active tab should have the active class
      assert html =~ "tabs-trigger-active"
    end

    test "sets aria-selected true on default tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:tab value="tab2">Tab 2</:tab>
          <:panel value="tab1">Panel 1</:panel>
          <:panel value="tab2">Panel 2</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(aria-selected="false")
    end

    test "shows default panel, hides others" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:tab value="tab2">Tab 2</:tab>
          <:panel value="tab1">Panel 1</:panel>
          <:panel value="tab2">Panel 2</:panel>
        </Tabs.tabs>
        """)

      # Non-default panel should be hidden
      assert html =~ "hidden"
    end
  end

  describe "tabs/1 disabled tabs" do
    test "renders disabled tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:tab value="tab2" disabled={true}>Tab 2</:tab>
          <:panel value="tab1">Panel 1</:panel>
          <:panel value="tab2">Panel 2</:panel>
        </Tabs.tabs>
        """)

      assert html =~ "disabled"
    end
  end

  describe "tabs/1 custom id" do
    test "uses provided id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="my-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(id="my-tabs")
      assert html =~ ~s(id="my-tabs-tab-tab1")
      assert html =~ ~s(id="my-tabs-panel-tab1")
    end
  end

  describe "tabs/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1" class="my-tabs">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ "my-tabs"
    end
  end

  describe "tabs/1 accessibility" do
    test "tabs have role=tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(role="tab")
    end

    test "panels have role=tabpanel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(role="tabpanel")
    end

    test "tablist has aria-orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(aria-orientation="horizontal")
    end

    test "tabs have aria-controls linking to panels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(aria-controls="test-panel-tab1")
    end

    test "panels have aria-labelledby linking to tabs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(aria-labelledby="test-tab-tab1")
    end

    test "default tab has tabindex 0, others have -1" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:tab value="tab2">Tab 2</:tab>
          <:panel value="tab1">Panel 1</:panel>
          <:panel value="tab2">Panel 2</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(tabindex="-1")
    end
  end

  describe "tabs/1 phx-hook" do
    test "has phx-hook for keyboard navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs id="test-tabs" default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(phx-hook="SutraUI.Tabs.Tabs")
    end
  end

  describe "segmented/1" do
    import SutraUI.HTMLHelpers

    test "is a radio group of real radio inputs with the chosen one checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" name="view" value="grid">
          <:option value="list" label="List" />
          <:option value="grid" label="Grid" />
        </Tabs.segmented>
        """)

      assert attribute(html, "#view", "role") == "radiogroup"
      assert attribute(html, "#view", "aria-label") == "View"
      assert count(html, "input[type=radio]") == 2
      assert attribute(html, "input[value=grid]", "checked") == ""
      assert attribute(html, "input[value=list]", "checked") == nil
      assert attribute(html, "input[value=list]", "name") == "view"
      assert attribute(html, "label[data-value=grid]", "data-state") == "active"
      assert attribute(html, "label[data-value=list]", "data-state") == "idle"
    end

    test "standalone click sends the value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" value="list" click="set_view" target="#panel">
          <:option value="list" label="List" />
          <:option value="grid" label="Grid" />
        </Tabs.segmented>
        """)

      assert attribute(html, "input[value=grid]", "phx-click") == "set_view"
      assert attribute(html, "input[value=grid]", "phx-value-value") == "grid"
      assert attribute(html, "input[value=grid]", "phx-target") == "#panel"
    end

    test "without click there are no phx attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" name="v">
          <:option value="a" label="A" />
        </Tabs.segmented>
        """)

      assert attribute(html, "input", "phx-click") == nil
      assert attribute(html, "input", "phx-value-value") == nil
    end

    test "a form field supplies name and value" do
      assigns = %{field: Phoenix.Component.to_form(%{"view" => "grid"})[:view]}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" field={@field}>
          <:option value="list" label="List" />
          <:option value="grid" label="Grid" />
        </Tabs.segmented>
        """)

      assert attribute(html, "input[value=grid]", "name") == "view"
      assert attribute(html, "input[value=grid]", "checked") == ""
    end

    test "an icon-only option is named by its title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" name="v">
          <:option value="list" title="List view"><svg data-icon="list"></svg></:option>
        </Tabs.segmented>
        """)

      assert text(html, "label span.sr-only") == "List view"
      assert attribute(html, "label", "title") == "List view"
      assert count(html, "label svg[data-icon=list]") == 1
    end

    test "disabled applies to the group or one option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" name="v">
          <:option value="a" label="A" />
          <:option value="b" label="B" disabled />
        </Tabs.segmented>
        """)

      assert attribute(html, "input[value=a]", "disabled") == nil
      assert attribute(html, "input[value=b]", "disabled") == ""

      all =
        rendered_to_string(~H"""
        <Tabs.segmented id="view" label="View" name="v" disabled>
          <:option value="a" label="A" />
        </Tabs.segmented>
        """)

      assert attribute(all, "input[value=a]", "disabled") == ""
    end
  end

  describe "filter_tabs/1" do
    import SutraUI.HTMLHelpers

    test "buttons carry aria-pressed, state, counts and the value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.filter_tabs id="f" label="Filter inbox">
          <:item label="All" count={42} active click="filter" value="all" />
          <:item label="Mine" count={3} click="filter" value="mine" />
        </Tabs.filter_tabs>
        """)

      assert attribute(html, "#f", "role") == "group"
      assert attribute(html, "#f", "aria-label") == "Filter inbox"
      assert attribute(html, "button[phx-value-filter=all]", "aria-pressed") == "true"
      assert attribute(html, "button[phx-value-filter=all]", "data-state") == "active"
      assert attribute(html, "button[phx-value-filter=mine]", "aria-pressed") == "false"
      assert attribute(html, "button[phx-value-filter=mine]", "data-state") == "idle"
      assert attribute(html, "button[phx-value-filter=mine]", "phx-click") == "filter"
      assert text(html, "button[phx-value-filter=all] .filter-tab-count") == "42"
      assert text(html, "button[phx-value-filter=mine]") == "Mine3"
    end

    test "links carry aria-current and no count when none is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.filter_tabs id="f" label="Filter">
          <:item label="All" active navigate="/inbox" />
          <:item label="Waiting" patch="/inbox?f=waiting" />
        </Tabs.filter_tabs>
        """)

      assert attribute(html, "a[href='/inbox']", "aria-current") == "page"
      assert attribute(html, "a[href='/inbox?f=waiting']", "aria-current") == nil
      assert attribute(html, "a[href='/inbox?f=waiting']", "data-phx-link") == "patch"
      assert count(html, ".filter-tab-count") == 0
      assert count(html, "button") == 0
    end

    test "the slot content leads the label and a target is passed through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.filter_tabs id="f" label="Filter" target="#panel">
          <:item label="Mine" click="filter" value="mine"><svg data-icon="user"></svg></:item>
        </Tabs.filter_tabs>
        """)

      assert count(html, "button svg[data-icon=user]") == 1
      assert attribute(html, "button", "phx-target") == "#panel"
    end
  end
end

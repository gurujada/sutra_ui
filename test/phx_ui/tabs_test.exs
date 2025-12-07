defmodule PhxUI.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Tabs

  describe "tabs/1 rendering" do
    test "renders tabs container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab2">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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

    test "generates unique id when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(id="tabs-)
    end
  end

  describe "tabs/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tabs.tabs default_value="tab1" class="my-tabs">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
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
        <Tabs.tabs default_value="tab1">
          <:tab value="tab1">Tab 1</:tab>
          <:panel value="tab1">Panel 1</:panel>
        </Tabs.tabs>
        """)

      assert html =~ ~s(phx-hook="PhxUI.Tabs.Tabs")
    end
  end
end

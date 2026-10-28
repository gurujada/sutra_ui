defmodule SutraUI.PopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Popover

  describe "popover/1 rendering" do
    test "renders with correct structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Popover content
        </Popover.popover>
        """)

      assert html =~ ~s(id="test-popover")
      assert html =~ "popover"
      assert html =~ "<button>Open</button>"
      assert html =~ "Popover content"
    end

    test "renders trigger slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button class="trigger-btn">Click me</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ "trigger-btn"
      assert html =~ "Click me"
      assert html =~ "popover-trigger"
    end

    test "renders content with data-popover attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          <p>Rich content here</p>
        </Popover.popover>
        """)

      assert html =~ "<p>Rich content here</p>"
      assert html =~ "data-popover"
    end
  end

  describe "popover/1 sides" do
    test "accepts all valid sides" do
      for side <- ~w(top bottom left right) do
        assigns = %{side: side}

        html =
          rendered_to_string(~H"""
          <Popover.popover id="test-popover" side={@side}>
            <:trigger>
              <button>Open</button>
            </:trigger>
            Content
          </Popover.popover>
          """)

        assert html =~ ~s(data-side="#{side}")
      end
    end

    test "defaults to auto side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(data-side="auto")
    end
  end

  describe "popover/1 alignment" do
    test "accepts all valid alignments" do
      for align <- ~w(start center end) do
        assigns = %{align: align}

        html =
          rendered_to_string(~H"""
          <Popover.popover id="test-popover" align={@align}>
            <:trigger>
              <button>Open</button>
            </:trigger>
            Content
          </Popover.popover>
          """)

        assert html =~ ~s(data-align="#{align}")
      end
    end

    test "defaults to start alignment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(data-align="start")
    end
  end

  describe "popover/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover" class="my-popover-class">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ "my-popover-class"
    end
  end

  describe "popover/1 accessibility" do
    test "has aria-expanded attribute on trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(aria-expanded="false")
    end

    test "has aria-controls pointing to content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(aria-controls="test-popover-content")
    end

    test "has role=dialog on content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(role="dialog")
    end

    test "content is hidden by default with aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Popover.popover id="test-popover">
          <:trigger>
            <button>Open</button>
          </:trigger>
          Content
        </Popover.popover>
        """)

      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "show_popover/2, hide_popover/2, and toggle_popover/2" do
    test "show_popover returns JS struct" do
      js = Popover.show_popover("test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_popover returns JS struct" do
      js = Popover.hide_popover("test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "toggle_popover returns JS struct" do
      js = Popover.toggle_popover("test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "show_popover with existing JS struct" do
      existing_js = Phoenix.LiveView.JS.push("some-event")
      js = Popover.show_popover(existing_js, "test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_popover with existing JS struct" do
      existing_js = Phoenix.LiveView.JS.push("some-event")
      js = Popover.hide_popover(existing_js, "test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "toggle_popover with existing JS struct" do
      existing_js = Phoenix.LiveView.JS.push("some-event")
      js = Popover.toggle_popover(existing_js, "test-popover")
      assert %Phoenix.LiveView.JS{} = js
    end
  end

  describe "closed popovers take no room" do
    setup do
      {:ok, css: File.read!("priv/static/sutra_ui.css")}
    end

    test "a closed [data-popover] is display: none and keeps its animation", %{css: css} do
      assert css =~ ~r/\[data-popover\] \{[^}]*transition-behavior: allow-discrete;/s
      assert css =~ ~r/@starting-style \{\s*opacity: 0;/
      assert css =~ ~r/&\[aria-hidden="true"\] \{\s*@apply hidden invisible opacity-0 scale-95;/
    end

    test "the other floating panels are display: none when closed", %{css: css} do
      for selector <- [
            ~s(.hover-card .hover-card-content[aria-hidden="true"]),
            ~s(.context-menu-popover[aria-hidden="true"]),
            ~s(.context-menu-sub-content[aria-hidden="true"])
          ] do
        assert css =~ Regex.compile!(Regex.escape(selector) <> ~S( \{\s*@apply hidden;))
      end

      # select list and tab-nav mobile menu nest the rule under their own block
      assert css =~
               ~r/\.select-popover,\s*\[data-popover\] \{[^}]*&\[aria-hidden="true"\] \{\s*@apply hidden;/s

      assert css =~ ~r/\.tab-nav-mobile-menu \{[^}]*&\[aria-hidden="true"\] \{\s*@apply hidden;/s
    end
  end
end

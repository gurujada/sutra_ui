defmodule PhxUI.ButtonTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Button

  describe "button/1 rendering" do
    test "renders as button element by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>Click me</Button.button>
        """)

      assert html =~ "<button"
      assert html =~ "Click me"
      assert html =~ ~s(type="button")
    end

    test "renders inner block content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>
          <span>Icon</span> Submit
        </Button.button>
        """)

      assert html =~ "<span>Icon</span>"
      assert html =~ "Submit"
    end
  end

  describe "button/1 variants" do
    test "accepts all valid variants" do
      for variant <- ~w(primary secondary destructive outline ghost link) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <Button.button variant={@variant}>Test</Button.button>
          """)

        # Should render without error
        assert html =~ "<button"
      end
    end
  end

  describe "button/1 sizes" do
    test "accepts all valid sizes" do
      for size <- ~w(default sm lg icon) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Button.button size={@size}>Test</Button.button>
          """)

        # Should render without error
        assert html =~ "<button"
      end
    end
  end

  describe "button/1 types" do
    test "renders with type=button by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>Test</Button.button>
        """)

      assert html =~ ~s(type="button")
    end

    test "renders with type=submit" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button type="submit">Submit</Button.button>
        """)

      assert html =~ ~s(type="submit")
    end

    test "renders with type=reset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button type="reset">Reset</Button.button>
        """)

      assert html =~ ~s(type="reset")
    end
  end

  describe "button/1 disabled state" do
    test "renders disabled attribute when disabled=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button disabled>Disabled</Button.button>
        """)

      assert html =~ "disabled"
    end

    test "does not render disabled attribute when disabled=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button disabled={false}>Enabled</Button.button>
        """)

      # Should not have disabled as an HTML attribute (disabled="..." or just disabled)
      # Note: disabled: appears in CSS classes which is fine
      refute html =~ ~r/<button[^>]*\sdisabled[\s>=]/
    end
  end

  describe "button/1 loading state" do
    test "sets aria-busy=true when loading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button loading>Loading...</Button.button>
        """)

      assert html =~ ~s(aria-busy="true")
    end

    test "disables button when loading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button loading>Loading...</Button.button>
        """)

      assert html =~ "disabled"
    end

    test "does not set aria-busy when not loading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button>Normal</Button.button>
        """)

      refute html =~ "aria-busy"
    end
  end

  describe "button/1 as link with navigate" do
    test "renders as Phoenix link with navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button navigate="/users">View Users</Button.button>
        """)

      assert html =~ ~s(href="/users")
      assert html =~ "data-phx-link"
      assert html =~ ~s(data-phx-link-state="push")
      assert html =~ "View Users"
    end
  end

  describe "button/1 as link with patch" do
    test "renders as Phoenix link with patch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button patch="/users/1/edit">Edit</Button.button>
        """)

      assert html =~ ~s(href="/users/1/edit")
      assert html =~ ~s(data-phx-link="patch")
    end
  end

  describe "button/1 as link with href" do
    test "renders as anchor tag with href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button href="https://example.com">External</Button.button>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="https://example.com")
      assert html =~ "External"
      # Should NOT have LiveView data attributes
      refute html =~ "data-phx-link"
    end
  end

  describe "button/1 accessibility" do
    test "passes through aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button size="icon" aria-label="Close dialog">X</Button.button>
        """)

      assert html =~ ~s(aria-label="Close dialog")
    end

    test "passes through aria-expanded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button aria-expanded="true">Menu</Button.button>
        """)

      assert html =~ ~s(aria-expanded="true")
    end

    test "passes through aria-controls" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button aria-controls="dropdown-menu">Open</Button.button>
        """)

      assert html =~ ~s(aria-controls="dropdown-menu")
    end

    test "passes through aria-pressed for toggle buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button aria-pressed="true">Bold</Button.button>
        """)

      assert html =~ ~s(aria-pressed="true")
    end
  end

  describe "button/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button class="my-custom-class">Custom</Button.button>
        """)

      assert html =~ "my-custom-class"
    end

    test "includes multiple custom classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button class="class-one class-two">Custom</Button.button>
        """)

      assert html =~ "class-one"
      assert html =~ "class-two"
    end
  end

  describe "button/1 global attributes" do
    test "passes through phx-click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button phx-click="handle_click">Click</Button.button>
        """)

      assert html =~ ~s(phx-click="handle_click")
    end

    test "passes through phx-target" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button phx-click="click" phx-target="#component">Click</Button.button>
        """)

      assert html =~ ~s(phx-target="#component")
    end

    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button id="my-button">Click</Button.button>
        """)

      assert html =~ ~s(id="my-button")
    end

    test "passes through name and value for form buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Button.button name="action" value="save">Save</Button.button>
        """)

      assert html =~ ~s(name="action")
      assert html =~ ~s(value="save")
    end
  end
end

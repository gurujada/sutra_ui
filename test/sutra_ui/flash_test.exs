defmodule SutraUI.FlashTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Flash

  describe "flash/1 rendering" do
    test "renders flash with info kind" do
      assigns = %{flash: %{"info" => "This is an info message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ "flash"
      assert html =~ "flash-info"
      assert html =~ "This is an info message"
    end

    test "renders flash with error kind" do
      assigns = %{flash: %{"error" => "This is an error message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:error} flash={@flash} />
        """)

      assert html =~ "flash"
      assert html =~ "flash-error"
      assert html =~ "This is an error message"
    end

    test "renders flash with title" do
      assigns = %{flash: %{"info" => "Message content"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} title="Success!" />
        """)

      assert html =~ "flash-title"
      assert html =~ "Success!"
      assert html =~ "Message content"
    end

    test "renders flash with inner_block content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info}>
          Custom inner block content
        </Flash.flash>
        """)

      assert html =~ "Custom inner block content"
    end

    test "does not render when flash is empty" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      refute html =~ "flash-info"
    end

    test "does not render when flash key is missing" do
      assigns = %{flash: %{"error" => "Only error"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      refute html =~ "flash-info"
      refute html =~ "Only error"
    end
  end

  describe "flash/1 id" do
    test "generates default id based on kind" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ ~s(id="flash-info")
    end

    test "accepts custom id" do
      assigns = %{flash: %{"error" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash id="my-custom-flash" kind={:error} flash={@flash} />
        """)

      assert html =~ ~s(id="my-custom-flash")
    end
  end

  describe "flash/1 icons" do
    test "renders info icon for info kind" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ "flash-icon"
      assert html =~ "<svg"
      # Info icon has a circle
      assert html =~ ~s(cx="12" cy="12" r="10")
    end

    test "renders error icon for error kind" do
      assigns = %{flash: %{"error" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:error} flash={@flash} />
        """)

      assert html =~ "flash-icon"
      assert html =~ "<svg"
      # Circle-alert icon has a circle with r="10"
      assert html =~ ~s(r="10")
    end
  end

  describe "flash/1 accessibility" do
    test "has role=alert" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ ~s(role="alert")
    end

    test "close button has aria-label" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ ~s(aria-label="close")
    end
  end

  describe "flash/1 close button" do
    test "renders close button" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ "flash-close"
      assert html =~ "<svg"
      # X icon paths
      assert html =~ "M18 6 6 18"
    end

    test "close button triggers clear flash" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} />
        """)

      assert html =~ "lv:clear-flash"
    end
  end

  describe "flash/1 global attributes" do
    test "passes through additional attributes" do
      assigns = %{flash: %{"info" => "Message"}}

      html =
        rendered_to_string(~H"""
        <Flash.flash kind={:info} flash={@flash} data-testid="test-flash" />
        """)

      assert html =~ ~s(data-testid="test-flash")
    end
  end
end

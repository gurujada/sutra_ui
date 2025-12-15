defmodule SutraUI.AvatarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Avatar

  describe "avatar/1 rendering" do
    test "renders as span element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar initials="JD" />
        """)

      assert html =~ "<span"
      assert html =~ "avatar"
    end

    test "renders image when src is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar src="https://example.com/avatar.jpg" alt="User" initials="JD" />
        """)

      assert html =~ "<img"
      assert html =~ ~s(src="https://example.com/avatar.jpg")
      assert html =~ ~s(alt="User")
    end

    test "renders initials in fallback" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar initials="AB" />
        """)

      assert html =~ "AB"
      assert html =~ "avatar-fallback"
    end

    test "renders default icon when no src or initials" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar />
        """)

      assert html =~ "<svg"
      # User icon has a circle for the head
      assert html =~ ~s(cx="12" cy="7" r="4")
    end

    test "renders custom fallback content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar src="/missing.jpg" alt="User">
          <:fallback>
            <span class="custom-icon">X</span>
          </:fallback>
        </Avatar.avatar>
        """)

      assert html =~ "custom-icon"
      assert html =~ "X"
    end
  end

  describe "avatar/1 sizes" do
    test "accepts all valid sizes" do
      for size <- ~w(sm md lg xl) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Avatar.avatar size={@size} initials="AB" />
          """)

        assert html =~ "avatar-#{size}"
      end
    end

    test "defaults to md size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar initials="AB" />
        """)

      assert html =~ "avatar-md"
    end
  end

  describe "avatar/1 shapes" do
    test "accepts all valid shapes" do
      for shape <- ~w(circle square) do
        assigns = %{shape: shape}

        html =
          rendered_to_string(~H"""
          <Avatar.avatar shape={@shape} initials="AB" />
          """)

        assert html =~ "avatar-#{shape}"
      end
    end

    test "defaults to circle shape" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar initials="AB" />
        """)

      assert html =~ "avatar-circle"
    end
  end

  describe "avatar/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar class="my-custom-class" initials="AB" />
        """)

      assert html =~ "my-custom-class"
    end
  end

  describe "avatar/1 accessibility" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar id="user-avatar" initials="AB" />
        """)

      assert html =~ ~s(id="user-avatar")
    end

    test "includes alt text on image" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar src="/avatar.jpg" alt="John Doe" initials="JD" />
        """)

      assert html =~ ~s(alt="John Doe")
    end
  end

  describe "avatar/1 fallback behavior" do
    test "fallback is hidden when image is present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar src="/avatar.jpg" alt="User" initials="AB" />
        """)

      assert html =~ "avatar-fallback-hidden"
    end

    test "fallback is visible when no image" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar initials="AB" />
        """)

      assert html =~ "avatar-fallback"
      refute html =~ "avatar-fallback-hidden"
    end
  end
end

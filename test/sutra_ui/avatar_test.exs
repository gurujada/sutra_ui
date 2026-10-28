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

  describe "avatar_group/1" do
    import SutraUI.HTMLHelpers

    @people [
      %{name: "Asha Rao"},
      %{name: "Ravi Teja", initials: "RT"},
      %{name: "Mei Lin Wong"},
      %{name: "Sam Cole"},
      %{name: "Dev Patel"}
    ]

    test "stacks up to max faces and collapses the rest to +n" do
      assigns = %{people: @people}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} max={3} />
        """)

      assert count(html, ".avatar-group-item") == 3
      assert text(html, ".avatar-group-more") == "+2"
      assert attribute(html, ".avatar-group", "data-total") == "5"
      assert attribute(html, ".avatar-group", "data-hidden") == "2"
      assert attribute(html, ".avatar-group-more", "title") == "Sam Cole, Dev Patel"
    end

    test "no +n when everyone fits" do
      assigns = %{people: Enum.take(@people, 2)}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} />
        """)

      assert count(html, ".avatar-group-item") == 2
      assert count(html, ".avatar-group-more") == 0
    end

    test "the group is named by its label and every name, hidden ones included" do
      assigns = %{people: @people}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} max={2} label="Reviewers" />
        """)

      assert attribute(html, "#g", "role") == "group"

      assert attribute(html, "#g", "aria-label") ==
               "Reviewers: Asha Rao, Ravi Teja, Mei Lin Wong, Sam Cole, Dev Patel"

      assert attribute(html, ".avatar-group-more", "aria-hidden") == "true"
    end

    test "without a label the names alone name the group" do
      assigns = %{people: Enum.take(@people, 2)}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} />
        """)

      assert attribute(html, "#g", "aria-label") == "Asha Rao, Ravi Teja"
    end

    test "each face carries its name and initials default to the name's first letters" do
      assigns = %{people: @people}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} max={3} />
        """)

      titles =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".avatar-group-item")
        |> LazyHTML.attribute("title")

      assert titles == ["Asha Rao", "Ravi Teja", "Mei Lin Wong"]

      initials =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query(".avatar-fallback")
        |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

      assert initials == ["AR", "RT", "ML", "+2"]
    end

    test "faces with an image get ids so the fallback hook runs under a CSP" do
      assigns = %{people: [%{name: "Asha Rao", src: "/a.png"}]}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} nonce="n0nce" />
        """)

      assert attribute(html, "span.avatar", "id") == "g-0"
      assert html =~ ~r/<script[^>]*nonce="n0nce"/
      refute html =~ "onerror"
    end

    test "size applies to every face" do
      assigns = %{people: @people}

      html =
        rendered_to_string(~H"""
        <Avatar.avatar_group id="g" people={@people} max={1} size="lg" />
        """)

      assert attribute(html, "#g", "data-size") == "lg"
      assert count(html, ".avatar-lg") == 2
    end
  end
end

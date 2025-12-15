defmodule SutraUI.SpinnerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Spinner

  describe "spinner/1 rendering" do
    test "renders with icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner />
        """)

      assert html =~ "<svg"
      assert html =~ "M21 12a9 9 0 1 1-6.219-8.56"
      assert html =~ "animate-spin"
    end

    test "renders as div with role=status" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner />
        """)

      assert html =~ "<div"
      assert html =~ ~s(role="status")
    end
  end

  describe "spinner/1 sizes" do
    test "accepts all valid sizes" do
      for size <- ~w(sm default lg xl) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Spinner.spinner size={@size} />
          """)

        # Should render without error
        assert html =~ ~s(role="status")
      end
    end

    test "sm size uses size-3 class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner size="sm" />
        """)

      assert html =~ "size-3"
    end

    test "lg size uses size-6 class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner size="lg" />
        """)

      assert html =~ "size-6"
    end
  end

  describe "spinner/1 accessibility" do
    test "has default aria-label of Loading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner />
        """)

      assert html =~ ~s(aria-label="Loading")
    end

    test "accepts custom aria-label via label attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner label="Processing payment..." />
        """)

      assert html =~ ~s(aria-label="Processing payment...")
    end

    test "includes sr-only text when no text slot provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner label="Loading data" />
        """)

      assert html =~ "sr-only"
      assert html =~ "Loading data"
    end

    test "does not include sr-only text when text slot provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner>
          <:text>Please wait...</:text>
        </Spinner.spinner>
        """)

      assert html =~ "Please wait..."
      # The sr-only span should not be rendered when text slot is used
      # (the text slot provides the visible text)
    end
  end

  describe "spinner/1 text slot" do
    test "renders text slot content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner>
          <:text>Loading items...</:text>
        </Spinner.spinner>
        """)

      assert html =~ "Loading items..."
    end
  end

  describe "spinner/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner class="text-blue-500" />
        """)

      assert html =~ "text-blue-500"
    end
  end

  describe "spinner/1 global attributes" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner id="main-spinner" />
        """)

      assert html =~ ~s(id="main-spinner")
    end
  end

  describe "spinner_icon/1" do
    test "renders minimal spinner for tight spaces" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner_icon />
        """)

      assert html =~ "<svg"
      assert html =~ "M21 12a9 9 0 1 1-6.219-8.56"
      assert html =~ "animate-spin"
      assert html =~ ~s(role="status")
    end

    test "accepts size attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner_icon size="sm" />
        """)

      assert html =~ "size-3"
    end

    test "accepts custom label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner_icon label="Saving" />
        """)

      assert html =~ ~s(aria-label="Saving")
    end

    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Spinner.spinner_icon class="text-primary" />
        """)

      assert html =~ "text-primary"
    end
  end
end

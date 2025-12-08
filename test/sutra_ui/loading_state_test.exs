defmodule SutraUI.LoadingStateTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.LoadingState

  describe "loading_state/1 rendering" do
    test "renders loading state with default message" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state />
        """)

      assert html =~ "loading-state"
      assert html =~ "Loading..."
    end

    test "renders with custom message" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state message="Processing data..." />
        """)

      assert html =~ "Processing data..."
    end

    test "renders spinner icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state />
        """)

      # Uses hero-arrow-path with animate-spin
      assert html =~ "hero-arrow-path"
      assert html =~ "animate-spin"
    end
  end

  describe "loading_state/1 card wrapper" do
    test "wraps in card by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state />
        """)

      assert html =~ "card"
    end

    test "does not wrap in card when wrap_card is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state wrap_card={false} />
        """)

      assert html =~ "loading-state"
      refute html =~ "card-content"
    end
  end

  describe "loading_state/1 spinner sizes" do
    test "defaults to lg spinner (size-6)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state />
        """)

      assert html =~ "size-6"
    end

    test "accepts sm spinner size (size-3)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state spinner_size="sm" />
        """)

      assert html =~ "size-3"
    end

    test "accepts default spinner size (size-4)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state spinner_size="default" />
        """)

      assert html =~ "size-4"
    end

    test "accepts xl spinner size (size-8)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state spinner_size="xl" />
        """)

      assert html =~ "size-8"
    end
  end

  describe "loading_state/1 custom classes" do
    test "accepts custom class without card" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state wrap_card={false} class="my-custom-class" />
        """)

      assert html =~ "loading-state"
      assert html =~ "my-custom-class"
    end

    test "accepts custom class with card" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <LoadingState.loading_state class="my-custom-class" />
        """)

      assert html =~ "my-custom-class"
    end
  end
end

defmodule SutraUI.MarqueeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Marquee

  describe "marquee/1 rendering" do
    test "renders with wrapper and track" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee"
      assert html =~ "marquee-track"
      assert html =~ "marquee-content"
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end

    test "duplicates content for seamless loop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item 1</:item>
        </Marquee.marquee>
        """)

      assert html =~ ~s(aria-hidden="true")
      assert length(Regex.scan(~r/Item 1/, html)) == 2
    end
  end

  describe "marquee/1 direction" do
    test "default direction is left" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-track"
      refute html =~ "marquee-reverse"
    end

    test "renders right direction" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee direction="right">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-reverse"
    end
  end

  describe "marquee/1 speed" do
    test "no speed class by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      refute html =~ "marquee-slow"
      refute html =~ "marquee-fast"
    end

    test "slow speed class on wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee speed="slow">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-slow"
    end

    test "fast speed class on wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee speed="fast">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-fast"
    end
  end

  describe "marquee/1 pause_on_hover" do
    test "includes pause class on wrapper by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-pause-on-hover"
    end

    test "excludes pause class when disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee pause_on_hover={false}>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      refute html =~ "marquee-pause-on-hover"
    end
  end

  describe "marquee/1 fade_edges" do
    test "includes fade class by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-fade"
    end

    test "excludes fade class when disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee fade_edges={false}>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      refute html =~ "marquee-fade"
    end
  end

  describe "marquee/1 gap" do
    test "no gap class by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee>
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      refute html =~ "marquee-gap-sm"
      refute html =~ "marquee-gap-lg"
    end

    test "renders small gap" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee gap="sm">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-gap-sm"
    end

    test "renders large gap" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee gap="lg">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "marquee-gap-lg"
    end
  end

  describe "marquee/1 custom class" do
    test "includes custom class on wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee class="my-marquee">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ "my-marquee"
    end
  end

  describe "marquee/1 global attributes" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Marquee.marquee id="news-ticker">
          <:item>Item</:item>
        </Marquee.marquee>
        """)

      assert html =~ ~s(id="news-ticker")
    end
  end
end

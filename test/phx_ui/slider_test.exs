defmodule PhxUI.SliderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Slider

  describe "slider/1 basic rendering" do
    test "renders a range input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" />
        """)

      assert html =~ "<input"
      assert html =~ ~s(type="range")
      assert html =~ ~s(id="volume")
    end

    test "renders with hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" />
        """)

      assert html =~ ~s(phx-hook="PhxUI.Slider.Slider")
    end

    test "renders with default values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" />
        """)

      assert html =~ ~s(min="0")
      assert html =~ ~s(max="100")
      assert html =~ ~s(step="1")
      assert html =~ ~s(value="50")
    end

    test "renders with custom values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="temp" min="-10" max="40" step="0.5" value="20" />
        """)

      assert html =~ ~s(min="-10")
      assert html =~ ~s(max="40")
      assert html =~ ~s(step="0.5")
      assert html =~ ~s(value="20")
    end

    test "renders with name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" name="settings[volume]" />
        """)

      assert html =~ ~s(name="settings[volume]")
    end
  end

  describe "slider/1 disabled state" do
    test "renders disabled when disabled=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" disabled />
        """)

      assert html =~ "disabled"
    end

    test "does not render disabled when disabled=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" disabled={false} />
        """)

      refute html =~ ~r/<input[^>]*\sdisabled[\s>=]/
    end
  end

  describe "slider/1 accessibility" do
    test "renders aria-valuemin" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" min="10" />
        """)

      assert html =~ ~s(aria-valuemin="10")
    end

    test "renders aria-valuemax" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" max="200" />
        """)

      assert html =~ ~s(aria-valuemax="200")
    end

    test "renders aria-valuenow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" value="75" />
        """)

      assert html =~ ~s(aria-valuenow="75")
    end

    test "renders aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" aria-label="Volume control" />
        """)

      assert html =~ ~s(aria-label="Volume control")
    end

    test "renders aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" aria-labelledby="volume-label" />
        """)

      assert html =~ ~s(aria-labelledby="volume-label")
    end

    test "renders aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" aria-describedby="volume-desc" />
        """)

      assert html =~ ~s(aria-describedby="volume-desc")
    end

    test "renders aria-valuetext" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="progress" aria-valuetext="75 percent complete" />
        """)

      assert html =~ ~s(aria-valuetext="75 percent complete")
    end
  end

  describe "slider/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" class="w-64" />
        """)

      assert html =~ "w-64"
    end
  end

  describe "slider/1 form integration" do
    test "renders with form attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" form="settings-form" />
        """)

      assert html =~ ~s(form="settings-form")
    end

    test "renders with phx-change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Slider.slider id="volume" phx-change="volume_changed" />
        """)

      assert html =~ ~s(phx-change="volume_changed")
    end
  end
end

defmodule PhxUI.ComponentCase do
  @moduledoc """
  Test case for PhxUI components.

  Provides helpers for rendering and testing Phoenix components.

  ## Example

      defmodule PhxUI.ButtonTest do
        use PhxUI.ComponentCase

        describe "button/1" do
          test "renders with default variant" do
            assigns = %{}

            html =
              rendered_to_string(~H\"""
              <PhxUI.Button.button>Click me</PhxUI.Button.button>
              \""")

            assert html =~ "Click me"
          end
        end
      end
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest
      import Phoenix.Component
      import PhxUI.ComponentCase
    end
  end

  @doc """
  Renders a HEEx template to a string for testing.
  """
  def render(template) do
    template
    |> Phoenix.LiveViewTest.rendered_to_string()
  end

  @doc """
  Renders a component function with assigns to a string.

  ## Example

      html = render_component(&Button.button/1, %{
        variant: "primary",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Click" end}]
      })
  """
  def render_component(component, assigns \\ %{}) do
    assigns
    |> component.()
    |> Phoenix.LiveViewTest.rendered_to_string()
  end

  @doc """
  Creates an inner_block slot with the given content.

  ## Example

      assigns = %{inner_block: slot_content("Click me")}
      html = render_component(&Button.button/1, assigns)
  """
  def slot_content(content) when is_binary(content) do
    [%{__slot__: :inner_block, inner_block: fn _, _ -> content end}]
  end

  @doc """
  Asserts that the HTML contains an element matching the selector.
  Uses Floki for parsing.

  ## Example

      assert_selector(html, "button[type='submit']")
  """
  def assert_selector(html, selector) do
    parsed = Floki.parse_document!(html)

    case Floki.find(parsed, selector) do
      [] -> flunk("Expected to find selector #{inspect(selector)} in:\n#{html}")
      _ -> true
    end
  end

  @doc """
  Refutes that the HTML contains an element matching the selector.
  Uses Floki for parsing.

  ## Example

      refute_selector(html, "button[disabled]")
  """
  def refute_selector(html, selector) do
    parsed = Floki.parse_document!(html)

    case Floki.find(parsed, selector) do
      [] ->
        true

      found ->
        flunk("Expected NOT to find selector #{inspect(selector)}, but found: #{inspect(found)}")
    end
  end

  @doc """
  Gets the value of an attribute from the first matching element.

  ## Example

      assert get_attribute(html, "button", "type") == "submit"
  """
  def get_attribute(html, selector, attribute) do
    parsed = Floki.parse_document!(html)

    case Floki.find(parsed, selector) do
      [] ->
        nil

      [element | _] ->
        Floki.attribute(element, attribute) |> List.first()
    end
  end

  @doc """
  Gets all values of an attribute from matching elements.

  ## Example

      classes = get_attributes(html, "button", "class")
  """
  def get_attributes(html, selector, attribute) do
    parsed = Floki.parse_document!(html)

    parsed
    |> Floki.find(selector)
    |> Enum.flat_map(&Floki.attribute(&1, attribute))
  end

  @doc """
  Asserts that an element has a specific class.

  ## Example

      assert_has_class(html, "button", "btn-primary")
  """
  def assert_has_class(html, selector, class) do
    classes = get_attribute(html, selector, "class") || ""

    if String.contains?(classes, class) do
      true
    else
      flunk(
        "Expected #{inspect(selector)} to have class #{inspect(class)}, but got: #{inspect(classes)}"
      )
    end
  end

  @doc """
  Refutes that an element has a specific class.
  """
  def refute_has_class(html, selector, class) do
    classes = get_attribute(html, selector, "class") || ""

    if String.contains?(classes, class) do
      flunk("Expected #{inspect(selector)} NOT to have class #{inspect(class)}")
    else
      true
    end
  end
end

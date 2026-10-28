defmodule SutraUI.DatePickerFieldTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  import SutraUI.ComponentCase,
    only: [assert_selector: 2, refute_selector: 2, get_attribute: 3]

  alias SutraUI.DatePicker

  @pickers [
    {&DatePicker.date_picker/1, "date", %{}},
    {&DatePicker.date_range_picker/1, "range", %{}},
    {&DatePicker.time_picker/1, "time", %{}},
    {&DatePicker.datetime_picker/1, "datetime", %{zone: "Etc/UTC"}}
  ]

  defp render_it(fun, attrs), do: render_component(fun, Map.new(attrs))

  for {fun, kind, extra} <- @pickers do
    describe "#{kind} picker field group" do
      test "label, description and errors sit in the same group as <.input>" do
        html =
          render_it(
            unquote(fun),
            %{
              id: "f",
              name: "f",
              label: "When",
              description: "Local time",
              errors: ["can't be blank"]
            }
            |> Map.merge(unquote(Macro.escape(extra)))
          )

        assert get_attribute(html, "div.fieldset", "class") == "fieldset mb-5 gap-1.5"
        assert_selector(html, ~s(label.label[for="f"]))
        assert html =~ "When"
        assert_selector(html, "p#f-description.field-description")
        assert_selector(html, "#f-error p.text-destructive")
        assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
        assert get_attribute(html, "input[data-dp]", "aria-invalid") == "true"
        assert get_attribute(html, "input[data-dp]", "aria-describedby") =~ "f-description"
        assert get_attribute(html, "input[data-dp]", "aria-describedby") =~ "f-error"
      end

      test "bare is the picker alone" do
        html =
          render_it(
            unquote(fun),
            %{id: "f", name: "f", label: "When", description: "d", errors: ["x"], bare: true}
            |> Map.merge(unquote(Macro.escape(extra)))
          )

        refute_selector(html, ".fieldset")
        refute_selector(html, "label.label")
        refute html =~ "field-description"
        refute_selector(html, "#f-error")
        assert_selector(html, ".date-picker")
      end

      test "no errors, no marks" do
        html =
          render_it(
            unquote(fun),
            %{id: "f", name: "f", label: "When"} |> Map.merge(unquote(Macro.escape(extra)))
          )

        assert get_attribute(html, "input[data-dp]", "aria-invalid") in [nil, ""]
        refute_selector(html, "#f-error")
      end
    end
  end

  describe "errors from a form field" do
    defp field(errors, used?) do
      params = if used?, do: %{"due" => ""}, else: %{}

      Phoenix.Component.to_form(params, as: :t, errors: errors)[:due]
    end

    test "shown once the field was used, translated" do
      html =
        render_it(&DatePicker.date_picker/1, %{
          field: field([due: {"must be after %{n}", n: 5}], true),
          label: "Due"
        })

      assert html =~ "must be after 5"
      assert get_attribute(html, "input[data-dp]", "aria-invalid") == "true"
    end

    test "hidden while the field is untouched" do
      html =
        render_it(&DatePicker.date_picker/1, %{
          field: field([due: {"is invalid", []}], false),
          label: "Due"
        })

      refute html =~ "is invalid"
    end
  end

  describe "<.input> with date and time types" do
    import Phoenix.Component

    test "type=date renders the picker once, in one field group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SutraUI.Input.input
          type="date"
          name="due"
          id="due"
          label="Due"
          errors={["late"]}
          min="2027-01-01"
        />
        """)

      assert_selector(html, ~s(input[type="date"]#due[data-dp="main"]))
      assert [_] = Regex.scan(~r/class="fieldset /, html)
      assert get_attribute(html, "#due-wrapper", "data-rules") =~ "2027-01-01"
      assert html =~ "late"
    end

    test "type=time renders the time picker with the step in minutes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SutraUI.Input.input type="time" name="at" id="at" label="At" step="900" />
        """)

      assert get_attribute(html, "#at-wrapper", "data-kind") == "time"
      assert get_attribute(html, "#at-wrapper", "data-step") == "15"
    end

    test "datetime-local with a zone is a datetime picker; without one it stays native" do
      assigns = %{}

      with_zone =
        rendered_to_string(~H"""
        <SutraUI.Input.input type="datetime-local" name="s" id="s" label="Start" zone="Etc/UTC" />
        """)

      without =
        rendered_to_string(~H"""
        <SutraUI.Input.input type="datetime-local" name="s" id="s" label="Start" />
        """)

      assert get_attribute(with_zone, "#s-wrapper", "data-kind") == "datetime"
      refute without =~ "date-picker"
      assert_selector(without, ~s(input[type="datetime-local"].input))
    end

    test "native keeps the browser's own control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SutraUI.Input.input type="date" name="d" id="d" label="D" native />
        """)

      refute html =~ "date-picker"
      assert_selector(html, ~s(input[type="date"].input))
    end
  end
end

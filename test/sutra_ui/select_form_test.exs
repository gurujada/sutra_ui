defmodule SutraUI.SelectFormTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  import SutraUI.ComponentCase,
    only: [assert_selector: 2, refute_selector: 2, get_attribute: 3, get_attributes: 3]

  alias SutraUI.Select

  @roles [{"Administrator", "admin"}, {"Teacher", "teacher"}, {"Guest", "guest", disabled: true}]

  defp render_select(attrs) do
    assigns = %{attrs: Map.new(attrs)}

    rendered_to_string(~H"""
    <Select.select {@attrs} />
    """)
  end

  describe "single" do
    test "a real select with the options, and the trigger shows the chosen label" do
      html = render_select(id: "role", name: "role", value: "teacher", options: @roles)

      assert_selector(html, ~s(select#role[name="role"] option[value="admin"]))
      assert_selector(html, ~s(select#role option[value="teacher"][selected]))
      assert_selector(html, ~s(select#role option[value="guest"][disabled]))
      assert get_attribute(html, "[data-select-wrapper], .select", "data-state") == "closed"
      assert get_attribute(html, "[data-has-select]", "data-mode") == "single"
      assert html =~ ~r/data-selected-label[^>]*>Teacher</
      refute_selector(html, "[data-selected-label][data-placeholder]")
    end

    test "the list is a listbox of options with ids, selection and disabled state" do
      html = render_select(id: "role", name: "role", value: "teacher", options: @roles)

      assert_selector(html, ~s(#role-listbox[role="listbox"]))

      assert get_attributes(html, ~s(#role-listbox [role="option"]), "data-value") ==
               ["admin", "teacher", "guest"]

      assert get_attributes(html, ~s(#role-listbox [role="option"]), "aria-selected") ==
               ["false", "true", "false"]

      assert get_attributes(html, ~s(#role-listbox [role="option"]), "aria-disabled") ==
               ["false", "false", "true"]

      refute_selector(html, "#role-listbox[aria-multiselectable]")
    end

    test "the trigger is a select-only combobox named by the label" do
      html = render_select(id: "role", name: "role", label: "Role", options: @roles)

      assert get_attribute(html, "button.select-trigger", "role") == "combobox"
      assert get_attribute(html, "button.select-trigger", "aria-label") == "Role"
      assert get_attribute(html, "button.select-trigger", "aria-expanded") == "false"
      assert get_attribute(html, "button.select-trigger", "aria-controls") == "role-listbox"
      assert get_attribute(html, "button.select-trigger", "aria-haspopup") == "listbox"
      assert get_attribute(html, ".select-sheet-title", "class") =~ "select-sheet-title"
      assert html =~ ~r/select-sheet-title">Role</
    end

    test "a prompt is the empty choice, in the select and the list, and marks a placeholder" do
      html = render_select(id: "role", name: "role", prompt: "Choose a role", options: @roles)

      assert_selector(html, ~s(select#role option[value=""][selected]))

      assert_selector(
        html,
        ~s(#role-listbox [role="option"][data-value=""][aria-selected="true"])
      )

      assert_selector(html, "[data-selected-label][data-placeholder]")
      assert html =~ ~r/data-selected-label[^>]*>Choose a role</
    end

    test "without a value or prompt the first enabled option shows, as the browser selects it" do
      html = render_select(id: "role", name: "role", options: @roles)

      assert_selector(html, ~s(select#role option[value="admin"][selected]))
      assert html =~ ~r/data-selected-label[^>]*>Administrator</
    end

    test "plain strings and atoms work as options and values" do
      html = render_select(id: "n", name: "n", value: :b, options: ["a", "b"])

      assert_selector(html, ~s(select#n option[value="b"][selected]))
    end

    test "groups render optgroups and role=group" do
      html =
        render_select(
          id: "stack",
          name: "stack",
          value: "vue",
          options: [{"Back", [{"Phoenix", "phoenix"}]}, {"Front", [{"Vue", "vue"}]}]
        )

      assert_selector(
        html,
        ~s(select#stack optgroup[label="Front"] option[value="vue"][selected])
      )

      assert_selector(html, ~s(#stack-listbox [role="group"]))
      assert html =~ "Back"
    end
  end

  describe "multiple" do
    test "several selected options show as chips and the listbox is multiselectable" do
      html =
        render_select(
          id: "tags",
          name: "tags[]",
          multiple: true,
          value: ["a", "c"],
          options: ["a", "b", "c"]
        )

      assert_selector(html, "select#tags[multiple]")
      assert get_attribute(html, "[data-has-select]", "data-mode") == "multiple"
      assert get_attributes(html, ".select-chip", "class") |> length() == 2
      assert html =~ ~r/select-chip">a</
      assert html =~ ~r/select-chip">c</
      assert get_attribute(html, "#tags-listbox", "aria-multiselectable") == "true"
      refute_selector(html, ~s(#tags-listbox [data-value=""]))
    end

    test "nothing selected shows the prompt as a placeholder" do
      html =
        render_select(id: "tags", name: "tags[]", multiple: true, prompt: "Pick", options: ["a"])

      assert_selector(html, "[data-selected-label][data-placeholder]")
      assert html =~ "Pick"
    end
  end

  describe "states" do
    test "disabled disables the select and the trigger and says so on the wrapper" do
      html = render_select(id: "r", name: "r", disabled: true, options: ["a"])

      assert_selector(html, "select#r[disabled]")
      assert_selector(html, "button.select-trigger[disabled]")
      assert_selector(html, "[data-has-select][data-disabled]")
    end

    test "invalid and described by pass to the select and the trigger" do
      html =
        render_select(
          id: "r",
          name: "r",
          options: ["a"],
          "aria-invalid": "true",
          "aria-describedby": "r-error",
          required: true
        )

      for sel <- ["select#r", "button.select-trigger"] do
        assert get_attribute(html, sel, "aria-invalid") == "true"
        assert get_attribute(html, sel, "aria-describedby") == "r-error"
      end

      assert_selector(html, "select#r[required]")
      assert get_attribute(html, "button.select-trigger", "aria-required") == "true"
    end

    test "search: automatic from ten options, forced either way" do
      many = Enum.map(1..10, &"o#{&1}")
      few = ["a", "b"]

      assert_selector(
        render_select(id: "s", name: "s", options: many),
        ".select-popover header input"
      )

      refute_selector(
        render_select(id: "s", name: "s", options: few),
        ".select-popover header input"
      )

      assert_selector(
        render_select(id: "s", name: "s", options: few, searchable: true),
        ".select-popover header input"
      )

      refute_selector(
        render_select(id: "s", name: "s", options: many, searchable: false),
        ".select-popover header input"
      )
    end

    test "the search box is an editable combobox with a name" do
      html = render_select(id: "s", name: "s", options: ["a"], searchable: true)

      assert get_attribute(html, ".select-popover header input", "role") == "combobox"
      assert get_attribute(html, ".select-popover header input", "aria-label") == "Search..."
      assert get_attribute(html, ".select-popover header input", "name") == nil
    end

    test "native renders only the browser's select" do
      html = render_select(id: "n", name: "n", native: true, options: ["a", "b"])

      assert_selector(html, "select#n option")
      refute_selector(html, "button")
      refute_selector(html, "[phx-hook]")
    end

    test "the hook is the extracted Select hook and nothing is inline" do
      html = render_select(id: "r", name: "r", options: ["a"])

      assert get_attribute(html, "[data-has-select]", "phx-hook") == "SutraUI.Select.Select"
      refute html =~ "<script"
      refute html =~ ~r/\sstyle=/
    end
  end

  describe "field" do
    test "id, name and value come from the form field" do
      form = Phoenix.Component.to_form(%{"role" => "teacher"}, as: :user)
      html = render_select(field: form[:role], options: @roles)

      assert_selector(
        html,
        ~s(select#user_role[name="user[role]"] option[value="teacher"][selected])
      )
    end

    test "a multiple field gets name[]" do
      form = Phoenix.Component.to_form(%{"tags" => ["a"]}, as: :user)
      html = render_select(field: form[:tags], multiple: true, options: ["a", "b"])

      assert_selector(html, ~s(select[name="user[tags][]"]))
    end

    test "no id, name or field is an error" do
      assert_raise ArgumentError, ~r/id/, fn -> render_select(options: ["a"]) end
    end
  end

  describe "custom option content" do
    test "keeps the hidden input and the option components" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="status" name="status" value="active">
          <:trigger>Status badge</:trigger>
          <Select.select_option value="active" label="Active" />
        </Select.select>
        """)

      assert_selector(html, ~s(input[type="hidden"][name="status"][value="active"]))
      refute_selector(html, "select")
      assert_selector(html, "#status[data-custom-trigger]")
      assert html =~ "Status badge"
    end
  end

  describe "input type=select" do
    test "label for the select, description and error wired to the field" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SutraUI.Input.input
          id="role"
          name="role"
          type="select"
          label="Role"
          description="Who they are"
          errors={["can't be blank"]}
          options={["a"]}
        />
        """)

      assert get_attribute(html, "label", "for") == "role"
      assert get_attribute(html, "select#role", "aria-invalid") == "true"
      assert get_attribute(html, "select#role", "aria-describedby") =~ "role-error"
      assert get_attribute(html, "button.select-trigger", "aria-describedby") =~ "role-error"
      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "native keeps the browser's select inside the field" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SutraUI.Input.input id="r" name="r" type="select" native options={["a"]} />
        """)

      refute_selector(html, "button")
      assert_selector(html, "select#r")
    end
  end
end

defmodule SutraUI.ConfirmTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias Phoenix.LiveView.JS
  alias SutraUI.Confirm

  defp doc(html), do: LazyHTML.from_fragment(html)
  defp q(html, selector), do: html |> doc() |> LazyHTML.query(selector)
  defp attr_of(html, selector, attr), do: html |> q(selector) |> LazyHTML.attribute(attr)

  describe "confirm_dialog/1" do
    setup do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Confirm.confirm_dialog
          id="retire"
          title="Retire this course?"
          consequence="Nobody can start it again."
          confirm="Retire"
          event="retire"
          values={%{"id" => "7"}}
        />
        """)

      %{html: html}
    end

    test "is an alert dialog, modal, named by the question and described by the consequence", %{
      html: html
    } do
      assert attr_of(html, "[role=alertdialog]", "aria-modal") == ["true"]
      assert attr_of(html, "[role=alertdialog]", "aria-labelledby") == ["retire-title"]
      assert attr_of(html, "[role=alertdialog]", "aria-describedby") == ["retire-description"]
      assert q(html, "#retire-title") |> LazyHTML.text() =~ "Retire this course?"
      assert q(html, "#retire-description") |> LazyHTML.text() =~ "Nobody can start it again."
    end

    test "is a div, never a native dialog", %{html: html} do
      assert Enum.count(q(html, "dialog")) == 0
      assert attr_of(html, "div#retire.dialog", "id") == ["retire"]
    end

    test "makes the page behind inert and starts focus on Keep for a danger action", %{html: html} do
      assert attr_of(html, "#retire", "data-inert-page") == ["true"]
      assert attr_of(html, "#retire", "data-initial-focus") == ["[data-confirm-keep]"]
    end

    test "offers Keep it next to the distinct verb, in a form that carries the values", %{
      html: html
    } do
      assert q(html, "[data-confirm-keep]") |> LazyHTML.text() =~ "Keep it"
      assert q(html, "[data-confirm-ok]") |> LazyHTML.text() =~ "Retire"
      assert attr_of(html, "[data-confirm-ok]", "type") == ["submit"]
      assert attr_of(html, "[data-confirm-ok]", "data-tone") == ["danger"]
      assert attr_of(html, "input[name=id]", "value") == ["7"]
      assert attr_of(html, "form", "id") == ["retire-form"]
    end

    test "Keep closes it; the verb pushes the event and closes it", %{html: html} do
      [keep] = attr_of(html, "[data-confirm-keep]", "phx-click")
      assert keep =~ "phx:hide-dialog"
      [submit] = attr_of(html, "form", "phx-submit")
      assert submit =~ "retire"
      assert submit =~ "phx:hide-dialog"
    end
  end

  test "a primary tone starts focus on the first field instead, with a primary verb" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Confirm.confirm_dialog
        id="send"
        title="Send it?"
        consequence="80 learners get an email."
        confirm="Send"
        event="send"
        tone={:primary}
      >
        <input name="note" />
      </Confirm.confirm_dialog>
      """)

    assert attr_of(html, "#send", "data-initial-focus") == []
    assert attr_of(html, "[data-confirm-ok]", "data-tone") == ["primary"]
    assert attr_of(html, "form input[name=note]", "name") == ["note"]
  end

  test "host-controlled: show opens it, Keep pushes on_cancel to the target" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Confirm.confirm_dialog
        id="rm"
        show
        title="Remove?"
        consequence="Today."
        confirm="Remove"
        event="remove"
        on_cancel="close_rm"
        target="#panel"
      />
      """)

    assert attr_of(html, "#rm", "class") |> hd() =~ "is-open"
    [keep] = attr_of(html, "[data-confirm-keep]", "phx-click")
    assert keep =~ "close_rm"
    assert keep =~ "#panel"
    [submit] = attr_of(html, "form", "phx-submit")
    refute submit =~ "phx:hide-dialog"
  end

  describe "confirm_host/1" do
    setup do
      assigns = %{}
      html = rendered_to_string(~H"<Confirm.confirm_host />")
      %{html: html}
    end

    test "is one hidden alert dialog with parts the catcher fills", %{html: html} do
      assert attr_of(html, "[data-sutra-confirm-host]", "phx-hook") != []
      assert attr_of(html, "[role=alertdialog]", "aria-modal") == ["true"]
      assert Enum.count(q(html, "[data-confirm-title]")) == 1
      assert Enum.count(q(html, "[data-confirm-message]")) == 1
      assert Enum.count(q(html, "dialog")) == 0
      refute attr_of(html, "div.dialog", "class") |> hd() =~ "is-open"
    end

    test "has a Keep button and a verb button for each tone, only the danger one visible", %{
      html: html
    } do
      assert q(html, "[data-confirm-cancel]") |> LazyHTML.text() =~ "Keep it"
      assert attr_of(html, "[data-confirm-ok]", "data-tone") == ["danger", "primary"]
      assert attr_of(html, "[data-confirm-ok][data-tone=primary]", "hidden") == [""]
      assert attr_of(html, "[data-confirm-ok][data-tone=danger]", "hidden") == []
    end

    test "its words can be translated" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Confirm.confirm_host title="¿Seguro?" confirm="Hacerlo" keep="Conservar" />
        """)

      assert q(html, "[data-confirm-title]") |> LazyHTML.text() =~ "¿Seguro?"
      assert q(html, "[data-confirm-cancel]") |> LazyHTML.text() =~ "Conservar"
      assert attr_of(html, "[data-confirm-ok]", "data-default-verb") == ["Hacerlo", "Hacerlo"]
    end
  end

  describe "open_confirm/1" do
    test "is reachable as SutraUI.open_confirm and adds the sticky class, then shows the dialog" do
      assert %JS{ops: ops} = SutraUI.open_confirm("retire")

      assert [
               ["add_class", %{names: ["is-open"], to: "#retire"}],
               ["dispatch", %{event: "phx:show-dialog"}]
             ] = ops
    end

    test "can be chained after other commands" do
      assert %JS{ops: [["push", _] | _]} = SutraUI.open_confirm(JS.push("x"), "retire")
    end

    test "close_confirm removes the class and hides" do
      assert %JS{ops: [["remove_class", _], ["dispatch", %{event: "phx:hide-dialog"}]]} =
               Confirm.close_confirm("retire")
    end
  end
end

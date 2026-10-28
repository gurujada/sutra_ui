defmodule SutraUI.ToastTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Toast

  defp html_of(html), do: LazyHTML.from_fragment(html)

  defp attr_of(html, selector, attr) do
    html |> html_of() |> LazyHTML.query(selector) |> LazyHTML.attribute(attr)
  end

  describe "default_duration/2" do
    test "info and success leave after 5 s, warnings after 8 s" do
      assert Toast.default_duration(:info) == 5000
      assert Toast.default_duration(:success) == 5000
      assert Toast.default_duration(:warning) == 8000
    end

    test "errors and toasts with an action stay until dismissed" do
      assert Toast.default_duration(:error) == 0
      assert Toast.default_duration(:info, %{label: "Undo", event: "undo"}) == 0
    end
  end

  describe "build/3" do
    test "defaults the duration by kind and gives every toast an id" do
      a = Toast.build(:info, "One", [])
      b = Toast.build(:info, "Two", [])
      assert a.id != b.id
      assert a.duration == 5000
      assert Toast.build(:error, "Bad", []).duration == 0
    end

    test "an explicit duration wins, also with an action" do
      toast =
        Toast.build(:info, "Deleted", duration: 8000, action: %{label: "Undo", event: "undo"})

      assert toast.duration == 8000
      assert toast.action == %{label: "Undo", event: "undo", values: %{}, target: nil}
    end

    test "an unknown kind raises" do
      assert_raise ArgumentError, ~r/unknown toast kind/, fn -> Toast.build(:loud, "x", []) end
    end

    test "an action needs a label and an event" do
      assert_raise ArgumentError, ~r/:label and :event/, fn ->
        Toast.build(:info, "x", action: %{label: "Undo"})
      end
    end
  end

  describe "toast/1" do
    for {kind, role, live, word} <- [
          {"info", "status", "polite", "info"},
          {"success", "status", "polite", "success"},
          {"warning", "alert", "assertive", "warning"},
          {"error", "alert", "assertive", "error"}
        ] do
      test "kind #{kind}: role #{role}, aria-live #{live}, data-kind and a named close button" do
        assigns = %{kind: unquote(kind)}

        html =
          rendered_to_string(~H"""
          <Toast.toast id="t" kind={@kind}>
            <:title>Heads up</:title>
            <:description>Some detail.</:description>
          </Toast.toast>
          """)

        assert attr_of(html, "#t", "data-kind") == [unquote(word)]
        assert attr_of(html, "#t", "role") == [unquote(role)]
        assert attr_of(html, "#t", "aria-live") == [unquote(live)]
        assert attr_of(html, "#t button", "aria-label") == ["Close"]
        assert html =~ "Heads up"
        assert html =~ "Some detail."
      end
    end

    test "variant is a deprecated alias of kind" do
      assigns = %{}

      destructive =
        rendered_to_string(~H"""
        <Toast.toast id="t" variant="destructive">
          <:title>x</:title>
        </Toast.toast>
        """)

      success =
        rendered_to_string(~H"""
        <Toast.toast id="t" variant="success">
          <:title>x</:title>
        </Toast.toast>
        """)

      assert attr_of(destructive, "#t", "data-kind") == ["error"]
      assert attr_of(success, "#t", "data-kind") == ["success"]
    end

    test "an unmanaged toast closes itself with a JS command; the icon is hidden from screen readers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="t">
          <:title>Hi</:title>
        </Toast.toast>
        """)

      assert [click] = attr_of(html, "#t button", "phx-click")
      assert click =~ "hide"
      assert attr_of(html, "#t .toast-icon", "aria-hidden") == ["true"]
    end

    test "the inner block replaces the inside and keeps the shell" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="t" kind="success">My own <b>content</b></Toast.toast>
        """)

      assert html =~ "My own"
      assert attr_of(html, "#t", "data-kind") == ["success"]
      assert attr_of(html, "#t button", "aria-label") == ["Close"]
      refute html =~ "toast-title"
    end

    test "the action slot renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="t">
          <:title>Uploaded</:title><:action><button>View</button></:action>
        </Toast.toast>
        """)

      assert html_of(html) |> LazyHTML.query("#t .toast-action button") |> LazyHTML.text() =~
               "View"
    end
  end

  describe "toast_group/1 without LiveView" do
    test "shows flash messages as toasts with a word and an icon, and no live component" do
      assigns = %{flash: %{"info" => "Saved", "error" => "Could not save"}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_group flash={@flash} />
        """)

      assert attr_of(html, "section", "data-live") == ["false"]
      assert attr_of(html, "section", "aria-label") == ["Notifications"]
      assert attr_of(html, "section", "phx-hook") != []
      assert attr_of(html, "[data-toast][data-kind=info]", "role") == ["status"]
      assert attr_of(html, "[data-toast][data-kind=error]", "role") == ["alert"]
      assert attr_of(html, "[data-toast][data-kind=error]", "data-duration") == ["0"]
      assert attr_of(html, "[data-toast][data-kind=info]", "data-duration") == ["5000"]
      assert html =~ "Saved"
      assert html =~ "Could not save"
      # state as a word (for screen readers) next to the icon; no visible title repeating the kind
      message = html_of(html) |> LazyHTML.query("[data-kind=error] .toast-message")
      assert LazyHTML.text(message) =~ "Error: Could not save"
      assert attr_of(html, "[data-kind=error] .toast-message .sr-only", "class") == ["sr-only"]

      assert html_of(html) |> LazyHTML.query("[data-kind=error] .toast-title") |> Enum.count() ==
               0

      refute html =~ "data-toast-notice"
    end

    test "queued toasts (put_toast) are shown too" do
      queued = Toast.build(:success, "Course published", id: "queued-1")
      assigns = %{flash: %{"sutra_toasts" => [queued]}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_group flash={@flash} />
        """)

      assert html =~ "Course published"
      assert attr_of(html, "[data-toast]", "data-kind") == ["success"]
    end

    test "an empty flash renders an empty stack" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast_group flash={%{}} />
        """)

      assert html_of(html) |> LazyHTML.query("[data-toast]") |> Enum.count() == 0
    end

    test "labels can be overridden and the corner is rendered" do
      assigns = %{flash: %{"error" => "Mala"}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_group
          flash={@flash}
          corner="top-center"
          labels={%{close: "Cerrar", error: "Fallo", region: "Avisos"}}
        />
        """)

      assert attr_of(html, "section", "data-corner") == ["top-center"]
      assert attr_of(html, "section", "aria-label") == ["Avisos"]
      assert attr_of(html, "[data-toast] button", "aria-label") == ["Cerrar"]
      assert html =~ "Fallo"
    end

    test "toast_container is a wrapper of the group" do
      # deprecated: called by name so the test does not warn
      assigns = %{flash: %{"info" => "Hello"}, class: nil, nonce: nil, __changed__: nil}
      html = rendered_to_string(apply(Toast, :toast_container, [assigns]))

      assert html =~ "Hello"
      assert attr_of(html, "section", "data-live") == ["false"]
    end
  end
end

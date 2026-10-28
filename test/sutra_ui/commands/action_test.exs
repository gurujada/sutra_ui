defmodule SutraUI.Commands.ActionTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.JS
  alias SutraUI.Commands.Action

  describe "new/1" do
    test "builds an action with one kind" do
      action = Action.new(id: "home", title: "Home", navigate: "/")

      assert %Action{id: "home", navigate: "/"} = action
      assert Action.kind(action) == :navigate
    end

    test "an action with only children opens a page" do
      parent = Action.new(id: "p", title: "P", children: [[id: "c", title: "C", copy: "x"]])

      assert Action.kind(parent) == nil
      assert [%Action{id: "c"}] = parent.children
    end

    test "needs an id, a title and a kind or children" do
      assert_raise ArgumentError, ~r/needs an id/, fn -> Action.new(title: "T", navigate: "/") end
      assert_raise ArgumentError, ~r/needs a title/, fn -> Action.new(id: "a", navigate: "/") end
      assert_raise ArgumentError, ~r/needs a kind/, fn -> Action.new(id: "a", title: "T") end
    end

    test "refuses several kinds" do
      assert_raise ArgumentError, ~r/several kinds/, fn ->
        Action.new(id: "a", title: "T", navigate: "/", copy: "x")
      end
    end

    test "refuses unknown options and bad tones" do
      assert_raise ArgumentError, ~r/unknown action options/, fn ->
        Action.new(id: "a", title: "T", navigate: "/", colour: "red")
      end

      assert_raise ArgumentError, ~r/tone/, fn ->
        Action.new(id: "a", title: "T", navigate: "/", tone: :loud)
      end
    end

    test "arguments need run or event, a valid type, and a source for search" do
      arg = %{name: :x, type: :text}

      assert_raise ArgumentError, ~r/args need/, fn ->
        Action.new(id: "a", title: "T", navigate: "/", args: [arg])
      end

      assert_raise ArgumentError, ~r/argument type/, fn ->
        Action.new(id: "a", title: "T", run: fn s, _ -> s end, args: [%{name: :x, type: :slider}])
      end

      assert_raise ArgumentError, ~r/needs a source/, fn ->
        Action.new(id: "a", title: "T", run: fn s, _ -> s end, args: [%{name: :x, type: :search}])
      end
    end
  end

  describe "allowed?/2" do
    test "disabled actions are not allowed; allow is asked with the socket" do
      assert Action.allowed?(Action.new(id: "a", title: "T", copy: "x"), :socket)
      refute Action.allowed?(Action.new(id: "a", title: "T", copy: "x", disabled: true), :socket)
      refute Action.allowed?(Action.new(id: "a", title: "T", copy: "x", disabled: "Why"), :socket)

      assert Action.allowed?(
               Action.new(id: "a", title: "T", copy: "x", allow: &(&1 == :yes)),
               :yes
             )

      refute Action.allowed?(
               Action.new(id: "a", title: "T", copy: "x", allow: &(&1 == :yes)),
               :no
             )
    end
  end

  describe "to_wire/1" do
    test "carries the kind and target but never a function" do
      wire =
        Action.to_wire(
          Action.new(id: "r", title: "Run", run: fn s, _ -> s end, allow: fn _ -> true end)
        )

      assert %{id: "r", kind: "server", target: nil} = wire
      assert Phoenix.json_library().encode!(wire) =~ ~s("kind":"server")
    end

    test "each kind has its target" do
      assert %{kind: "navigate", target: "/a"} =
               Action.to_wire(Action.new(id: "a", title: "A", navigate: "/a"))

      assert %{kind: "patch", target: "/a"} =
               Action.to_wire(Action.new(id: "a", title: "A", patch: "/a"))

      assert %{kind: "href", target: "https://x.test"} =
               Action.to_wire(Action.new(id: "a", title: "A", href: "https://x.test"))

      assert %{kind: "copy", target: "text"} =
               Action.to_wire(Action.new(id: "a", title: "A", copy: "text"))

      assert %{kind: "event", target: %{event: "go", payload: %{"a" => 1}}} =
               Action.to_wire(Action.new(id: "a", title: "A", event: "go", payload: %{"a" => 1}))

      assert %{kind: "js", target: json} =
               Action.to_wire(Action.new(id: "a", title: "A", js: JS.add_class("x", to: "#y")))

      assert is_binary(json) and json =~ "add_class"
    end

    test "disabled, confirm, tone and arguments" do
      wire =
        Action.to_wire(
          Action.new(
            id: "a",
            title: "A",
            tone: :danger,
            disabled: "Not yet",
            confirm: "Sure?",
            confirm_label: "Yes, delete",
            event: "go",
            args: [%{name: :who, type: :choice, choices: ["a", {"b", "Bee"}]}]
          )
        )

      assert %{
               tone: "danger",
               disabled: "Not yet",
               confirm: "Sure?",
               confirm_label: "Yes, delete"
             } = wire

      assert [
               %{
                 name: "who",
                 type: "choice",
                 required: true,
                 choices: [%{value: "a", label: "a"}, %{value: "b", label: "Bee"}]
               }
             ] =
               wire.args
    end
  end
end

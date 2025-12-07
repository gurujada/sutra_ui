defmodule PhxUI.LiveSelectTest do
  use ExUnit.Case, async: true

  alias PhxUI.LiveSelect

  describe "decode/1" do
    test "returns empty list for nil" do
      assert LiveSelect.decode(nil) == []
    end

    test "returns nil for empty string" do
      assert LiveSelect.decode("") == nil
    end

    test "decodes JSON string" do
      assert LiveSelect.decode(~s({"name":"Berlin"})) == %{"name" => "Berlin"}
    end

    test "decodes simple string" do
      assert LiveSelect.decode(~s("hello")) == "hello"
    end

    test "decodes number" do
      assert LiveSelect.decode("42") == 42
    end

    test "decodes list of JSON strings" do
      result = LiveSelect.decode([~s({"id":1}), ~s({"id":2})])
      assert result == [%{"id" => 1}, %{"id" => 2}]
    end

    test "decodes complex nested structure" do
      json = ~s({"city":"New York","coords":[40.7,-74.0]})
      assert LiveSelect.decode(json) == %{"city" => "New York", "coords" => [40.7, -74.0]}
    end
  end
end

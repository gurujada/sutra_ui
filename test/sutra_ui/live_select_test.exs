defmodule SutraUI.LiveSelectTest do
  use ExUnit.Case, async: true

  alias SutraUI.LiveSelect

  # =============================================================================
  # decode/1 Tests
  # =============================================================================

  describe "decode/1" do
    test "returns empty list for nil" do
      assert LiveSelect.decode(nil) == []
    end

    test "returns nil for empty string" do
      assert LiveSelect.decode("") == nil
    end

    test "decodes JSON object" do
      assert LiveSelect.decode(~s({"name":"Berlin"})) == %{"name" => "Berlin"}
    end

    test "decodes JSON string" do
      assert LiveSelect.decode(~s("hello")) == "hello"
    end

    test "decodes number" do
      assert LiveSelect.decode("42") == 42
    end

    test "decodes float" do
      assert LiveSelect.decode("3.14") == 3.14
    end

    test "decodes list of JSON strings" do
      result = LiveSelect.decode([~s({"id":1}), ~s({"id":2})])
      assert result == [%{"id" => 1}, %{"id" => 2}]
    end

    test "decodes complex nested structure" do
      json = ~s({"city":"New York","coords":[40.7,-74.0]})
      assert LiveSelect.decode(json) == %{"city" => "New York", "coords" => [40.7, -74.0]}
    end

    test "returns original value if not valid JSON" do
      assert LiveSelect.decode("hello world") == "hello world"
    end

    test "returns original value for invalid JSON in list" do
      result = LiveSelect.decode(["not json", ~s({"valid":true})])
      assert result == ["not json", %{"valid" => true}]
    end

    test "decodes boolean values" do
      assert LiveSelect.decode("true") == true
      assert LiveSelect.decode("false") == false
    end

    test "decodes null" do
      assert LiveSelect.decode("null") == nil
    end

    test "decodes JSON array" do
      assert LiveSelect.decode("[1,2,3]") == [1, 2, 3]
    end
  end

  # =============================================================================
  # normalize_options/1 Tests
  # =============================================================================

  describe "normalize_options/1" do
    test "normalizes simple strings" do
      options = ["New York", "Los Angeles", "Chicago"]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "New York", disabled: false},
               %{label: "Los Angeles", value: "Los Angeles", disabled: false},
               %{label: "Chicago", value: "Chicago", disabled: false}
             ]
    end

    test "normalizes atoms" do
      options = [:new_york, :los_angeles]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: :new_york, value: :new_york, disabled: false},
               %{label: :los_angeles, value: :los_angeles, disabled: false}
             ]
    end

    test "normalizes numbers" do
      options = [1, 2, 3]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: 1, value: 1, disabled: false},
               %{label: 2, value: 2, disabled: false},
               %{label: 3, value: 3, disabled: false}
             ]
    end

    test "normalizes 2-tuples {label, value}" do
      options = [{"New York", "nyc"}, {"Los Angeles", "la"}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "nyc", disabled: false},
               %{label: "Los Angeles", value: "la", disabled: false}
             ]
    end

    test "normalizes 2-tuples with complex values" do
      options = [{"Berlin", %{lat: 52.52, lng: 13.405}}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "Berlin", value: %{lat: 52.52, lng: 13.405}, disabled: false}
             ]
    end

    test "normalizes 3-tuples {label, value, disabled}" do
      options = [{"Active", "active", false}, {"Disabled", "disabled", true}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "Active", value: "active", disabled: false},
               %{label: "Disabled", value: "disabled", disabled: true}
             ]
    end

    test "normalizes maps with :label and :value" do
      options = [%{label: "New York", value: "nyc"}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "nyc", disabled: false, sticky: false, tag_label: nil}
             ]
    end

    test "normalizes maps with :key (alias for :label)" do
      options = [%{key: "New York", value: "nyc"}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "nyc", disabled: false, sticky: false, tag_label: nil}
             ]
    end

    test "normalizes maps with :value only" do
      options = [%{value: "nyc"}]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "nyc", value: "nyc", disabled: false, sticky: false, tag_label: nil}
             ]
    end

    test "normalizes maps with all optional fields" do
      options = [
        %{label: "New York", value: "nyc", disabled: true, sticky: true, tag_label: "NY"}
      ]

      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "nyc", disabled: true, sticky: true, tag_label: "NY"}
             ]
    end

    test "normalizes keyword lists" do
      options = [[label: "New York", value: "nyc"]]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "New York", value: "nyc", disabled: false, sticky: false, tag_label: nil}
             ]
    end

    test "normalizes plain map (keys as labels, sorted)" do
      options = %{NYC: "nyc", LA: "la", Chicago: "chi"}
      normalized = LiveSelect.normalize_options(options)

      # Map is sorted by key
      assert normalized == [
               %{label: :Chicago, value: "chi", disabled: false},
               %{label: :LA, value: "la", disabled: false},
               %{label: :NYC, value: "nyc", disabled: false}
             ]
    end

    test "skips invalid option formats" do
      options = ["valid", {:only_one_element}, nil, "also_valid"]
      normalized = LiveSelect.normalize_options(options)

      assert normalized == [
               %{label: "valid", value: "valid", disabled: false},
               %{label: "also_valid", value: "also_valid", disabled: false}
             ]
    end

    test "normalizes empty list" do
      assert LiveSelect.normalize_options([]) == []
    end

    test "normalizes empty map" do
      assert LiveSelect.normalize_options(%{}) == []
    end

    test "handles nil gracefully" do
      assert LiveSelect.normalize_options(nil) == []
    end

    test "preserves order for list options" do
      options = ["Z", "A", "M"]
      normalized = LiveSelect.normalize_options(options)
      labels = Enum.map(normalized, & &1.label)
      assert labels == ["Z", "A", "M"]
    end

    test "handles mixed option formats" do
      options = [
        "simple",
        {"tuple", "val"},
        %{label: "map", value: "mv"},
        [label: "keyword", value: "kv"]
      ]

      normalized = LiveSelect.normalize_options(options)

      assert length(normalized) == 4
      assert Enum.at(normalized, 0).label == "simple"
      assert Enum.at(normalized, 1).label == "tuple"
      assert Enum.at(normalized, 2).label == "map"
      assert Enum.at(normalized, 3).label == "keyword"
    end
  end

  # =============================================================================
  # Round-trip Tests (encode then decode)
  # =============================================================================

  describe "encode/decode round-trip" do
    test "simple string survives round trip" do
      original = "hello"
      # Strings are passed through as-is for simple values
      assert LiveSelect.decode(original) == "hello"
    end

    test "map value survives round trip via JSON" do
      original = %{id: 1, name: "test"}
      encoded = Jason.encode!(original)
      decoded = LiveSelect.decode(encoded)

      # Note: atom keys become string keys after JSON round-trip
      assert decoded == %{"id" => 1, "name" => "test"}
    end

    test "list of maps survives round trip" do
      original = [%{id: 1}, %{id: 2}]
      encoded = Enum.map(original, &Jason.encode!/1)
      decoded = LiveSelect.decode(encoded)

      assert decoded == [%{"id" => 1}, %{"id" => 2}]
    end
  end

  # =============================================================================
  # Integration-style Tests
  # =============================================================================

  describe "form integration patterns" do
    test "decodes single selection from form params" do
      # Simulating what comes from a form for single mode
      params = %{"city" => ~s({"id":1,"name":"NYC"})}
      decoded = LiveSelect.decode(params["city"])

      assert decoded == %{"id" => 1, "name" => "NYC"}
    end

    test "decodes multiple selections from form params (tags mode)" do
      # Simulating what comes from a form for tags mode
      params = %{"cities" => [~s({"id":1}), ~s({"id":2}), ~s({"id":3})]}
      decoded = LiveSelect.decode(params["cities"])

      assert decoded == [%{"id" => 1}, %{"id" => 2}, %{"id" => 3}]
    end

    test "handles empty selection gracefully" do
      params = %{"city" => ""}
      decoded = LiveSelect.decode(params["city"])

      assert decoded == nil
    end

    test "handles missing selection gracefully" do
      params = %{}
      decoded = LiveSelect.decode(params["city"])

      assert decoded == []
    end

    test "handles simple string values (no JSON)" do
      params = %{"city" => "nyc"}
      decoded = LiveSelect.decode(params["city"])

      assert decoded == "nyc"
    end
  end
end

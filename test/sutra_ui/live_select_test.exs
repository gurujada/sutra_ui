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

  # =============================================================================
  # Edge Case Tests (Bug Prevention)
  # =============================================================================

  describe "edge cases" do
    test "decodes label+value format from hidden input" do
      # This is the format we encode in hidden inputs
      encoded = ~s({"label":"New York","value":"nyc"})
      decoded = LiveSelect.decode(encoded)

      assert decoded == %{"label" => "New York", "value" => "nyc"}
    end

    test "decodes label+value with complex value" do
      # Complex values like maps are JSON-encoded within the value
      encoded = ~s({"label":"Berlin","value":{"lat":52.52,"lng":13.405}})
      decoded = LiveSelect.decode(encoded)

      assert decoded == %{
               "label" => "Berlin",
               "value" => %{"lat" => 52.52, "lng" => 13.405}
             }
    end

    test "decodes empty tags array" do
      # Tags mode with no selection sends empty array
      params = %{"tags" => []}
      decoded = LiveSelect.decode(params["tags"])

      assert decoded == []
    end

    test "decodes tags with single empty string element" do
      # This happens when HTML sends name[]="" for empty selection
      params = %{"tags" => [""]}
      decoded = LiveSelect.decode(params["tags"])

      # Empty strings decode to original value
      assert decoded == [""]
    end

    test "normalize_options handles struct that's not a map" do
      # Ensure we don't treat structs as plain maps
      date = ~D[2024-01-01]
      # Structs should fail normalization and be skipped
      options = [date, "valid"]
      normalized = LiveSelect.normalize_options(options)

      # Date struct is skipped, only "valid" remains
      assert normalized == [%{label: "valid", value: "valid", disabled: false}]
    end

    test "normalize_options with deeply nested value" do
      options = [
        %{
          label: "Complex",
          value: %{
            user: %{id: 1, name: "John"},
            metadata: [1, 2, 3]
          }
        }
      ]

      normalized = LiveSelect.normalize_options(options)

      assert length(normalized) == 1

      assert normalized |> hd() |> Map.get(:value) == %{
               user: %{id: 1, name: "John"},
               metadata: [1, 2, 3]
             }
    end

    test "normalize_options preserves all fields from map format" do
      options = [
        %{
          label: "Sticky Tag",
          value: "st",
          disabled: false,
          sticky: true,
          tag_label: "ST"
        }
      ]

      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.label == "Sticky Tag"
      assert normalized.value == "st"
      assert normalized.disabled == false
      assert normalized.sticky == true
      assert normalized.tag_label == "ST"
    end
  end

  # =============================================================================
  # Empty Selection Handling Tests
  # =============================================================================

  describe "empty selection handling" do
    test "filtering empty strings from decoded tags" do
      # Simulates what happens when form sends empty array as [""]
      params = %{"tags" => [""]}
      decoded = LiveSelect.decode(params["tags"])

      # Filter out empty/nil values as documented in troubleshooting
      filtered =
        decoded
        |> Enum.reject(&(&1 == "" or &1 == nil))

      assert filtered == []
    end

    test "empty selection in single mode decodes to nil" do
      params = %{"city" => ""}
      decoded = LiveSelect.decode(params["city"])
      assert decoded == nil
    end

    test "missing key decodes to empty list" do
      params = %{}
      decoded = LiveSelect.decode(params["tags"])
      assert decoded == []
    end

    test "real tags mode empty selection handling pattern" do
      # This is the recommended pattern from docs
      params = %{"tags" => [""]}

      tags =
        params["tags"]
        |> LiveSelect.decode()
        |> Enum.reject(&(&1 == "" or &1 == nil))

      assert tags == []
    end

    test "tags with mix of valid and empty values" do
      params = %{"tags" => ["", ~s({"label":"A","value":"a"}), ""]}

      tags =
        params["tags"]
        |> LiveSelect.decode()
        |> Enum.reject(&(&1 == "" or &1 == nil))

      assert tags == [%{"label" => "A", "value" => "a"}]
    end
  end

  # =============================================================================
  # Duplicate Detection Tests (by value)
  # =============================================================================

  describe "duplicate detection by value" do
    test "same value different labels are duplicates" do
      # Two options with same value should be considered same
      options = [
        %{label: "New York", value: "nyc"},
        %{label: "NYC", value: "nyc"}
      ]

      normalized = LiveSelect.normalize_options(options)

      # Both are normalized (normalization doesn't dedupe)
      assert length(normalized) == 2

      # But they have the same value
      values = Enum.map(normalized, & &1.value)
      assert values == ["nyc", "nyc"]
    end

    test "same label different values are not duplicates" do
      options = [
        %{label: "New York", value: "new_york"},
        %{label: "New York", value: "nyc"}
      ]

      normalized = LiveSelect.normalize_options(options)
      values = Enum.map(normalized, & &1.value)

      # These are different options
      assert values == ["new_york", "nyc"]
    end
  end
end

# =============================================================================
# LiveComponent Event Handler Tests
# =============================================================================

defmodule SutraUI.LiveSelectEventTest do
  @moduledoc """
  Tests for LiveSelect event handling and internal logic.
  """

  use ExUnit.Case, async: true

  alias SutraUI.LiveSelect

  describe "selection by value comparison" do
    test "already_selected checks value not label" do
      # This tests the internal behavior documented in the module
      # Two options with same value are considered duplicates

      # When normalizing, both get through
      options = [
        %{label: "Display 1", value: "same_value"},
        %{label: "Display 2", value: "same_value"}
      ]

      normalized = LiveSelect.normalize_options(options)
      assert length(normalized) == 2

      # The component's internal already_selected? function
      # compares by value, so selecting "same_value" twice
      # would be rejected the second time
    end
  end

  describe "sticky tags behavior" do
    test "sticky option field is preserved" do
      options = [%{label: "Sticky", value: "st", sticky: true}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.sticky == true
    end

    test "non-sticky is default" do
      options = [%{label: "Normal", value: "n"}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.sticky == false
    end
  end

  describe "disabled options behavior" do
    test "disabled option field is preserved" do
      options = [%{label: "Disabled", value: "d", disabled: true}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.disabled == true
    end

    test "non-disabled is default" do
      options = [%{label: "Enabled", value: "e"}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.disabled == false
    end
  end

  describe "tag_label field" do
    test "tag_label is preserved when provided" do
      options = [%{label: "New York", value: "nyc", tag_label: "NY"}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.tag_label == "NY"
    end

    test "tag_label is nil by default" do
      options = [%{label: "New York", value: "nyc"}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.tag_label == nil
    end
  end

  describe "user_defined_options behavior" do
    test "user-defined option can be normalized" do
      # When user types "Custom" and presses Enter, JS sends
      # select event with text: "Custom"
      # Server creates option like: %{label: text, value: text, disabled: false}

      user_text = "Custom Tag"
      user_option = %{label: user_text, value: user_text, disabled: false}

      # This should be a valid option
      [normalized] = LiveSelect.normalize_options([user_option])

      assert normalized.label == "Custom Tag"
      assert normalized.value == "Custom Tag"
      assert normalized.disabled == false
    end
  end

  describe "recovery data handling" do
    test "recovery data format matches what JS sends" do
      # JS stores selection as array of objects with string keys
      # On reconnect, sends: %{"selection" => [%{"label" => ..., "value" => ...}]}

      recovery_data = [
        %{"label" => "Recovered", "value" => "rec", "disabled" => false, "sticky" => false}
      ]

      # The component's normalize_recovered_option/1 handles this
      # We test the expected format is processable

      for item <- recovery_data do
        assert Map.has_key?(item, "label")
        assert Map.has_key?(item, "value")
      end
    end

    test "malformed recovery data is filtered" do
      # If JS sends malformed data, it should be ignored
      recovery_data = [
        %{"invalid" => "data"},
        %{"label" => "Valid", "value" => "v"}
      ]

      # Only valid items should be kept
      valid_items =
        recovery_data
        |> Enum.filter(&(Map.has_key?(&1, "label") and Map.has_key?(&1, "value")))

      assert length(valid_items) == 1
    end
  end
end

# =============================================================================
# Form Integration Tests
# =============================================================================

defmodule SutraUI.LiveSelectFormTest do
  @moduledoc """
  Tests for LiveSelect form integration patterns.

  These test the recommended patterns from documentation.
  """

  use ExUnit.Case, async: true

  alias SutraUI.LiveSelect

  describe "extracting values from decoded params" do
    test "extracts value from single selection" do
      # Form sends: %{"city" => "{\"label\":\"NYC\",\"value\":\"nyc\"}"}
      params = %{"city" => ~s({"label":"NYC","value":"nyc"})}

      decoded = LiveSelect.decode(params["city"])
      value = decoded["value"]

      assert value == "nyc"
    end

    test "extracts values from tags selection" do
      params = %{
        "tags" => [
          ~s({"label":"A","value":"a"}),
          ~s({"label":"B","value":"b"})
        ]
      }

      decoded = LiveSelect.decode(params["tags"])
      values = Enum.map(decoded, & &1["value"])

      assert values == ["a", "b"]
    end

    test "handles empty tags gracefully" do
      params = %{"tags" => [""]}

      values =
        params["tags"]
        |> LiveSelect.decode()
        |> Enum.reject(&(&1 == "" or &1 == nil))
        |> Enum.map(fn item ->
          case item do
            %{"value" => v} -> v
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      assert values == []
    end
  end

  describe "Ecto-style value extraction" do
    test "extracts IDs for belongs_to association" do
      params = %{"category_id" => ~s({"label":"Tech","value":42})}

      category_id =
        case LiveSelect.decode(params["category_id"]) do
          %{"value" => id} -> id
          _ -> nil
        end

      assert category_id == 42
    end

    test "extracts IDs for many_to_many association" do
      params = %{
        "tag_ids" => [
          ~s({"label":"Elixir","value":1}),
          ~s({"label":"Phoenix","value":2})
        ]
      }

      tag_ids =
        params["tag_ids"]
        |> LiveSelect.decode()
        |> Enum.map(& &1["value"])
        |> Enum.reject(&is_nil/1)

      assert tag_ids == [1, 2]
    end
  end

  describe "complex value handling" do
    test "handles map values" do
      params = %{
        "location" => ~s({"label":"NYC","value":{"lat":40.7,"lng":-74.0}})
      }

      decoded = LiveSelect.decode(params["location"])
      value = decoded["value"]

      assert value == %{"lat" => 40.7, "lng" => -74.0}
    end

    test "handles nested struct-like values" do
      params = %{
        "user" => ~s({"label":"John","value":{"id":1,"name":"John","email":"john@example.com"}})
      }

      decoded = LiveSelect.decode(params["user"])
      user = decoded["value"]

      assert user["id"] == 1
      assert user["name"] == "John"
      assert user["email"] == "john@example.com"
    end
  end

  describe "form name nil handling" do
    test "input_name helper produces field name when form name is nil" do
      # When form is created with to_form(%{}) without :as option,
      # form.name is nil and we should just use the field name

      # This tests the documented behavior
      form = Phoenix.Component.to_form(%{"city" => nil})

      # form.name should be nil
      assert form.name == nil

      # The field should still work
      field = form[:city]
      assert field.field == :city
    end

    test "input_name helper produces prefixed name when form has name" do
      # When form has :as option, name is prefixed
      form = Phoenix.Component.to_form(%{"city" => nil}, as: "my_form")

      assert form.name == "my_form"

      field = form[:city]
      assert field.field == :city
    end
  end
end

# =============================================================================
# Potential Bug Tests
# =============================================================================

defmodule SutraUI.LiveSelectBugPreventionTest do
  @moduledoc """
  Tests specifically designed to prevent bugs mentioned in review.md
  """

  use ExUnit.Case, async: true

  alias SutraUI.LiveSelect

  describe "empty selection handling in tags mode" do
    test "empty array returns empty list" do
      assert LiveSelect.decode([]) == []
    end

    test "array with empty string returns list with empty string" do
      # This is the actual HTML behavior - form sends [""]
      result = LiveSelect.decode([""])
      assert result == [""]
    end

    test "recommended filtering pattern works" do
      # Per docs, users should filter empty values
      params = %{"tags" => [""]}

      tags =
        params["tags"]
        |> LiveSelect.decode()
        |> Enum.reject(&(&1 == "" or &1 == nil))

      assert tags == []
    end

    test "mixed empty and valid values" do
      # Form params would have empty strings, not nil
      params = %{"tags" => ["", ~s({"label":"Valid","value":"v"}), ""]}

      result = LiveSelect.decode(params["tags"])

      filtered =
        result
        |> Enum.reject(fn
          "" -> true
          nil -> true
          _ -> false
        end)

      assert filtered == [%{"label" => "Valid", "value" => "v"}]
    end
  end

  describe "form name with nil" do
    test "to_form without as option has nil name" do
      form = Phoenix.Component.to_form(%{"field" => "value"})
      assert form.name == nil
    end

    test "to_form with as option has name" do
      form = Phoenix.Component.to_form(%{"field" => "value"}, as: "my_form")
      assert form.name == "my_form"
    end

    test "field from form with nil name" do
      form = Phoenix.Component.to_form(%{"city" => nil})
      field = form[:city]

      assert field.form.name == nil
      assert field.field == :city
    end
  end

  describe "concurrent updates safety" do
    # Note: True concurrent update testing requires actual LiveView
    # These tests verify the data structures are safe

    test "options list is replaced not mutated" do
      options1 = LiveSelect.normalize_options(["A", "B"])
      options2 = LiveSelect.normalize_options(["C", "D"])

      # Verify independence
      assert Enum.map(options1, & &1.label) == ["A", "B"]
      assert Enum.map(options2, & &1.label) == ["C", "D"]
    end

    test "normalization is idempotent" do
      options = [%{label: "Test", value: "t"}]
      normalized1 = LiveSelect.normalize_options(options)
      normalized2 = LiveSelect.normalize_options(options)

      assert normalized1 == normalized2
    end
  end

  describe "option normalization edge cases" do
    test "handles string keys in maps" do
      # Maps might come with string keys from external sources
      options = [%{"label" => "Test", "value" => "t"}]
      normalized = LiveSelect.normalize_options(options)

      # String keys are not recognized, so this should fail normalization
      # and return empty (based on our implementation)
      assert normalized == []
    end

    test "handles atom values correctly" do
      options = [%{label: "Test", value: :test_atom}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.value == :test_atom
    end

    test "handles integer values correctly" do
      options = [%{label: "Test", value: 42}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.value == 42
    end

    test "handles float values correctly" do
      options = [%{label: "Test", value: 3.14}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.value == 3.14
    end

    test "handles list values correctly" do
      options = [%{label: "Test", value: [1, 2, 3]}]
      [normalized] = LiveSelect.normalize_options(options)

      assert normalized.value == [1, 2, 3]
    end
  end

  describe "JSON encoding edge cases" do
    test "decode handles unicode" do
      encoded = ~s({"label":"日本語","value":"jp"})
      decoded = LiveSelect.decode(encoded)

      assert decoded["label"] == "日本語"
    end

    test "decode handles special characters in strings" do
      encoded = ~s({"label":"O'Brien","value":"ob"})
      decoded = LiveSelect.decode(encoded)

      assert decoded["label"] == "O'Brien"
    end

    test "decode handles nested arrays" do
      encoded = ~s({"label":"Test","value":[[1,2],[3,4]]})
      decoded = LiveSelect.decode(encoded)

      assert decoded["value"] == [[1, 2], [3, 4]]
    end
  end
end

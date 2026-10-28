defmodule SutraUI.TestFacadeTest do
  use ExUnit.Case, async: true

  test "the one import reaches the date, toast and confirm helpers" do
    for {name, arity} <- [
          pick: 3,
          pick: 4,
          params: 2,
          params: 3,
          assert_toast: 3,
          refute_toast: 2,
          refute_toast: 3,
          confirm: 2,
          confirm: 3
        ] do
      assert function_exported?(SutraUI.Test, name, arity), "SutraUI.Test.#{name}/#{arity}"
    end
  end

  test "params delegates to the picker's own" do
    assert SutraUI.Test.params("task[due]", ~D[2027-03-15]) ==
             %{"task" => %{"due" => "2027-03-15"}}
  end
end

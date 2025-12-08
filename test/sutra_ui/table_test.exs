defmodule SutraUI.TableTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Table

  describe "table/1 rendering" do
    test "renders table element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Table.table>
          <thead>
            <tr>
              <th>Header</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Cell</td>
            </tr>
          </tbody>
        </Table.table>
        """)

      assert html =~ "<table"
      assert html =~ ~s(class="table)
    end

    test "renders inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Table.table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>John</td>
              <td>john@example.com</td>
            </tr>
          </tbody>
        </Table.table>
        """)

      assert html =~ "Name"
      assert html =~ "Email"
      assert html =~ "John"
      assert html =~ "john@example.com"
    end
  end

  describe "table/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Table.table class="my-table">
          <tbody>
            <tr>
              <td>Cell</td>
            </tr>
          </tbody>
        </Table.table>
        """)

      assert html =~ "my-table"
    end
  end

  describe "table/1 with id" do
    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Table.table id="users-table">
          <tbody>
            <tr>
              <td>Cell</td>
            </tr>
          </tbody>
        </Table.table>
        """)

      assert html =~ ~s(id="users-table")
    end
  end

  describe "data_table/1 rendering" do
    test "renders table with columns" do
      assigns = %{users: [%{name: "Alice", email: "alice@example.com"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Email">{user.email}</:col>
        </Table.data_table>
        """)

      assert html =~ "<table"
      assert html =~ "Name"
      assert html =~ "Email"
      assert html =~ "Alice"
      assert html =~ "alice@example.com"
    end

    test "renders multiple rows" do
      assigns = %{
        users: [
          %{name: "Alice", email: "alice@example.com"},
          %{name: "Bob", email: "bob@example.com"},
          %{name: "Charlie", email: "charlie@example.com"}
        ]
      }

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Email">{user.email}</:col>
        </Table.data_table>
        """)

      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "Charlie"
    end

    test "renders empty table when no rows" do
      assigns = %{users: []}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.data_table>
        """)

      assert html =~ "<table"
      assert html =~ "<thead"
      assert html =~ "<tbody"
      assert html =~ "Name"
    end
  end

  describe "data_table/1 with caption" do
    test "renders caption" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:caption>User List</:caption>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.data_table>
        """)

      assert html =~ "<caption"
      assert html =~ "User List"
    end

    test "renders without caption" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.data_table>
        """)

      refute html =~ "<caption"
    end
  end

  describe "data_table/1 with action column" do
    test "renders action column" do
      assigns = %{users: [%{id: 1, name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:action :let={user}>
            <a href={"/users/#{user.id}"}>View</a>
          </:action>
        </Table.data_table>
        """)

      assert html =~ "View"
      assert html =~ ~s(href="/users/1")
    end

    test "renders action with label" do
      assigns = %{users: [%{id: 1, name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:action :let={_user} label="Actions">
            <button>Edit</button>
          </:action>
        </Table.data_table>
        """)

      assert html =~ "Actions"
      assert html =~ "Edit"
    end
  end

  describe "data_table/1 with footer" do
    test "renders footer" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:footer>
            <td colspan="2">Total: 1 user</td>
          </:footer>
        </Table.data_table>
        """)

      assert html =~ "<tfoot"
      assert html =~ "Total: 1 user"
    end
  end

  describe "data_table/1 column classes" do
    test "applies class to column cells" do
      assigns = %{users: [%{name: "Alice", balance: 100}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Balance" class="text-right">{user.balance}</:col>
        </Table.data_table>
        """)

      assert html =~ "text-right"
    end
  end

  describe "data_table/1 custom class" do
    test "includes custom class" do
      assigns = %{users: [%{name: "Alice"}]}

      html =
        rendered_to_string(~H"""
        <Table.data_table rows={@users} class="striped-table">
          <:col :let={user} label="Name">{user.name}</:col>
        </Table.data_table>
        """)

      assert html =~ "striped-table"
    end
  end
end

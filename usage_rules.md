# Sutra UI Usage Rules for LLMs

This document provides guidelines for AI assistants when working with the Sutra UI component library.

## Overview

Sutra UI is a pure Phoenix LiveView UI component library with no external dependencies. Components use colocated JavaScript hooks where interactivity is needed.

**Requirements:**
- Phoenix 1.8+ (for colocated hooks)
- Phoenix LiveView 1.1+ (ColocatedHook support)
- Tailwind CSS v4 (CSS-first configuration)

## Core Principles

### 1. CSS-First Styling

All component styling is defined in `priv/static/sutra_ui.css`. When modifying components:

- **DO**: Use CSS classes from `sutra_ui.css`
- **DO**: Add new CSS classes to `sutra_ui.css` when needed
- **DON'T**: Add inline Tailwind classes directly in component templates
- **DON'T**: Use helper functions to generate Tailwind class strings

**Pattern for class attributes:**
```elixir
# Good - uses CSS class with optional user override
class={["component-class", @class]}

# Avoid - inline Tailwind
class={["flex items-center gap-2", @class]}
```

### 2. Required ID Attributes

Components that require JavaScript hooks or generate DOM references **must** have a required `id` attribute:

```elixir
# Good - explicit required ID
attr(:id, :string, required: true, doc: "Unique identifier for the component")

# Avoid - auto-generated IDs
attr(:id, :string, default: fn -> "component-#{System.unique_integer()}" end)
```

**Rationale:**
- Predictable IDs aid debugging
- Prevents LiveView diffing issues on reconnect
- User maintains control over their DOM

### 3. Event Naming Convention

Custom JavaScript events use the `sutra-ui:` namespace:

```javascript
// Good
this.el.dispatchEvent(new CustomEvent('sutra-ui:component-action', { detail: {...} }))

// Avoid
this.el.dispatchEvent(new CustomEvent('component-action', { detail: {...} }))
```

### 4. Attribute Types

Use appropriate attribute types:

| Attribute | Type | Notes |
|-----------|------|-------|
| `class` | `:string` | Always `:string`, merged internally with list pattern |
| `id` | `:string` | Required for hook-based components |
| `disabled` | `:boolean` | Boolean attributes |
| `value` | `:string` or `:any` | Depends on component needs |
| `errors` | `:list` | List of error messages |

### 5. Slot Conventions

Slots should follow consistent patterns:

```elixir
# Simple content slot
slot(:inner_block, doc: "Main content")

# Named slot with attributes
slot :item, doc: "List items" do
  attr(:value, :string, required: true)
  attr(:disabled, :boolean)
end
```

## Component Patterns

### Basic Component Structure

```elixir
defmodule SutraUI.ComponentName do
  @moduledoc """
  Brief description of the component.

  ## Examples

      <.component_name id="my-component" required_attr="value">
        Content here
      </.component_name>

  ## Accessibility

  - List ARIA attributes used
  - Keyboard navigation support
  - Screen reader considerations
  """

  use Phoenix.Component

  @doc """
  Renders the component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Main content")

  def component_name(assigns) do
    ~H"""
    <div id={@id} class={["component-class", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
```

### Hook-Based Component Structure

```elixir
defmodule SutraUI.InteractiveComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Required for JavaScript hook")
  # ... other attrs

  def interactive_component(assigns) do
    ~H"""
    <div id={@id} class="component-class" phx-hook=".ComponentHook" data-option={@option}>
      {render_slot(@inner_block)}
    </div>

    <script :type={ColocatedHook} name=".ComponentHook">
      export default {
        mounted() {
          // Initialize component
        },
        updated() {
          // Handle LiveView updates
        },
        destroyed() {
          // Cleanup
        }
      }
    </script>
    """
  end
end
```

## Available Components

### Foundation
- `icon/1` - Icon rendering (requires icon CSS setup)
- `button/1` - Buttons with variants: primary, secondary, outline, ghost, link, destructive
- `badge/1` - Status badges
- `spinner/1` - Loading indicators
- `kbd/1` - Keyboard shortcut display

### Form Controls
- `label/1` - Form labels
- `input/1` - Text inputs (text, email, password, number, etc.)
- `textarea/1` - Multi-line text input
- `checkbox/1` - Checkbox input
- `switch/1` - Toggle switch
- `radio_group/1`, `radio/1` - Radio button groups
- `field/1`, `fieldset/1` - Field containers with label/description/error
- `select/1` - Custom select dropdown (JS hook)
- `slider/1` - Range slider (JS hook)
- `range_slider/1` - Dual-handle range slider (JS hook)
- `live_select/1` - Async searchable select (JS hook)

### Layout & Data Display
- `card/1` - Card container with header/content/footer slots
- `header/1` - Page header with title/subtitle/actions
- `table/1` - Data table with column definitions
- `skeleton/1` - Loading placeholder
- `empty/1` - Empty state display
- `alert/1` - Alert/callout messages
- `progress/1` - Progress bar

### Navigation & Interactive
- `breadcrumb/1` - Breadcrumb navigation
- `pagination/1` - Page navigation
- `accordion/1` - Collapsible content sections
- `tabs/1` - Tab panels (JS hook)
- `dropdown_menu/1` - Dropdown menu (JS hook)
- `toast/1`, `toaster/1` - Toast notifications (JS hook)

### Advanced UI
- `avatar/1` - User avatars with fallback
- `tooltip/1` - CSS-only hover tooltips
- `dialog/1` - Modal dialogs
- `popover/1` - Click-triggered popups
- `command/1` - Command palette with search (JS hook)
- `carousel/1` - CSS scroll-snap carousel

### Layout Helpers
- `filter_bar/1` - Filter bar for index pages
- `input_group/1` - Input with prefix/suffix
- `item/1` - Versatile list item
- `loading_state/1` - Loading indicator with message
- `simple_form/1` - Form wrapper with auto-styling

### Navigation
- `nav_pills/1` - Responsive navigation pills
- `sidebar/1` - Collapsible sidebar navigation
- `tab_nav/1` - Server-side routed tab navigation
- `theme_switcher/1` - Light/dark theme toggle

## CSS Class Naming

CSS classes in `sutra_ui.css` follow these conventions:

```css
/* Component base */
.component-name { }

/* Variants */
.component-name-variant { }

/* States */
.component-name-disabled { }
.component-name-active { }

/* Sub-elements */
.component-name-header { }
.component-name-content { }
.component-name-footer { }
```

## Testing Components

Tests are in `test/sutra_ui/` and use `ComponentCase`:

```elixir
defmodule SutraUI.ComponentNameTest do
  use ComponentCase, async: true

  import SutraUI.ComponentName

  describe "component_name/1" do
    test "renders with required attributes" do
      html = render_component(&component_name/1, id: "test", required: "value")
      assert html =~ ~s(id="test")
    end

    test "applies custom class" do
      html = render_component(&component_name/1, id: "test", class: "custom")
      assert html =~ "custom"
    end
  end
end
```

## Common Mistakes to Avoid

1. **Missing required `id`** on hook-based components
2. **Inline Tailwind** instead of CSS classes
3. **Auto-generating IDs** instead of requiring them
4. **Missing accessibility attributes** (ARIA, roles, keyboard support)
5. **Not updating moduledoc examples** when changing required attrs
6. **Forgetting to add new components** to `lib/sutra_ui.ex` imports

## File Structure

```
lib/
  sutra_ui/
    component_name.ex    # Component module
  sutra_ui.ex            # Main module with imports
priv/
  static/
    sutra_ui.css         # All component styles
test/
  sutra_ui/
    component_name_test.exs
  support/
    component_case.ex    # Test helpers
```

## Adding a New Component

1. Create `lib/sutra_ui/component_name.ex` with moduledoc and examples
2. Add CSS classes to `priv/static/sutra_ui.css`
3. Add import to `lib/sutra_ui.ex` in `__using__` macro
4. Update component list in `lib/sutra_ui.ex` moduledoc
5. Create tests in `test/sutra_ui/component_name_test.exs`
6. Update this file if the component introduces new patterns

## Common Recipes

### Modal Dialog with Form

```heex
<.dialog id="edit-user-dialog">
  <:title>Edit User</:title>
  <:description>Update user information below.</:description>
  
  <.simple_form for={@form} phx-submit="save_user">
    <.input field={@form[:name]} label="Name" />
    <.input field={@form[:email]} label="Email" type="email" />
    
    <:actions>
      <.button variant="outline" phx-click={SutraUI.Dialog.hide_dialog("edit-user-dialog")}>
        Cancel
      </.button>
      <.button type="submit">Save Changes</.button>
    </:actions>
  </.simple_form>
</.dialog>

<.button phx-click={SutraUI.Dialog.show_dialog("edit-user-dialog")}>
  Edit User
</.button>
```

### Data Table with Pagination

```heex
<.data_table rows={@users}>
  <:col :let={user} label="Name">{user.name}</:col>
  <:col :let={user} label="Email">{user.email}</:col>
  <:col :let={user} label="Status">
    <.badge variant={status_variant(user.status)}>{user.status}</.badge>
  </:col>
  <:action :let={user}>
    <.dropdown_menu id={"user-actions-#{user.id}"}>
      <:trigger>
        <.button variant="ghost" size="icon" aria-label="Actions">
          <.icon name="lucide-more-horizontal" />
        </.button>
      </:trigger>
      <:content>
        <.dropdown_menu_item navigate={~p"/users/#{user.id}"}>View</.dropdown_menu_item>
        <.dropdown_menu_item navigate={~p"/users/#{user.id}/edit"}>Edit</.dropdown_menu_item>
        <.dropdown_menu_separator />
        <.dropdown_menu_item variant="destructive" phx-click="delete_user" phx-value-id={user.id}>
          Delete
        </.dropdown_menu_item>
      </:content>
    </.dropdown_menu>
  </:action>
</.data_table>

<.pagination
  page={@page}
  total_pages={@total_pages}
  path={~p"/users"}
/>
```

### Form with Validation Errors

```heex
<.simple_form for={@form} phx-change="validate" phx-submit="save">
  <.field field={@form[:name]} label="Name" required>
    <.input field={@form[:name]} />
  </.field>
  
  <.field field={@form[:email]} label="Email" required>
    <.input field={@form[:email]} type="email" />
  </.field>
  
  <.field field={@form[:role]} label="Role">
    <.select id="role-select" name={@form[:role].name} value={@form[:role].value}>
      <.select_option value="admin" label="Administrator" />
      <.select_option value="user" label="Standard User" />
      <.select_option value="viewer" label="Viewer" />
    </.select>
  </.field>
  
  <:actions>
    <.button type="submit" loading={@saving}>Save</.button>
  </:actions>
</.simple_form>
```

### Confirmation Dialog Pattern

```elixir
# In your LiveView
def handle_event("confirm_delete", %{"id" => id}, socket) do
  socket = assign(socket, :delete_target_id, id)
  {:noreply, push_event(socket, "js-exec", %{to: "#confirm-delete-dialog", attr: "phx-show-dialog"})}
end

def handle_event("delete_confirmed", _, socket) do
  MyApp.delete_item(socket.assigns.delete_target_id)
  {:noreply, 
   socket
   |> put_flash(:info, "Item deleted")
   |> push_navigate(to: ~p"/items")}
end
```

```heex
<.dialog id="confirm-delete-dialog">
  <:title>Delete Item</:title>
  <:description>This action cannot be undone. Are you sure?</:description>
  <:footer>
    <.button variant="outline" phx-click={SutraUI.Dialog.hide_dialog("confirm-delete-dialog")}>
      Cancel
    </.button>
    <.button variant="destructive" phx-click="delete_confirmed">
      Delete
    </.button>
  </:footer>
</.dialog>
```

### Tabs with Dynamic Content

```heex
<.tabs id="content-tabs" default_value="overview">
  <:tab value="overview">Overview</:tab>
  <:tab value="activity">Activity</:tab>
  <:tab value="settings">Settings</:tab>
  
  <:panel value="overview">
    <.card>
      <:header>
        <:title>Overview</:title>
      </:header>
      <:content>
        <p>Overview content here...</p>
      </:content>
    </.card>
  </:panel>
  
  <:panel value="activity">
    <.card>
      <:header>
        <:title>Recent Activity</:title>
      </:header>
      <:content>
        <ul>
          <.item :for={activity <- @activities}>
            {activity.description}
          </.item>
        </ul>
      </:content>
    </.card>
  </:panel>
  
  <:panel value="settings">
    <.simple_form for={@settings_form} phx-submit="save_settings">
      <.switch field={@settings_form[:notifications]} label="Enable notifications" />
      <.switch field={@settings_form[:dark_mode]} label="Dark mode" />
    </.simple_form>
  </:panel>
</.tabs>
```

### Toast Notifications from LiveView

```elixir
# Show toast on successful action
def handle_event("save", params, socket) do
  case save_data(params) do
    {:ok, _record} ->
      {:noreply,
       socket
       |> put_flash(:info, "Changes saved successfully")}
    
    {:error, changeset} ->
      {:noreply, assign(socket, :form, to_form(changeset))}
  end
end

# Or use push_event for more control
def handle_event("export_complete", _, socket) do
  {:noreply,
   push_event(socket, "toast", %{
     variant: "success",
     title: "Export Complete",
     description: "Your data has been exported to CSV.",
     duration: 5000
   })}
end
```

## Troubleshooting

### Component hooks not working

**Symptoms:** Hook-based components (Select, Dialog, Tabs, etc.) don't respond to interactions.

**Solutions:**

1. **Check Phoenix version** - Colocated hooks require Phoenix 1.8+:
   ```elixir
   # mix.exs
   {:phoenix, "~> 1.8"}
   ```

2. **Verify hook import** - Ensure colocated hooks are imported in `app.js`:
   ```javascript
   // app.js
   import { hooks as sutraUiHooks } from "phoenix-colocated/sutra_ui";
   
   let liveSocket = new LiveSocket("/live", Socket, {
     hooks: { ...sutraUiHooks }
   })
   ```

3. **Check component ID** - Hook-based components require unique IDs:
   ```heex
   <%# Wrong - missing ID %>
   <.select name="country">
   
   <%# Correct %>
   <.select id="country-select" name="country">
   ```

### CSS styles not applied

**Symptoms:** Components render but look unstyled or broken.

**Solutions:**

1. **Check Tailwind v4 setup** - Verify `@source` directive in `app.css`:
   ```css
   @import "tailwindcss";
   @source "../../deps/sutra_ui/lib";
   @import "../../deps/sutra_ui/priv/static/sutra_ui.css";
   ```

2. **Check import order** - Sutra UI CSS must come after Tailwind:
   ```css
   @import "tailwindcss";
   @import "../../deps/sutra_ui/priv/static/sutra_ui.css";
   /* Your overrides come last */
   ```

3. **Clear cache** - After changing CSS config:
   ```bash
   mix assets.clean
   mix phx.server
   ```

### Form values not updating

**Symptoms:** Select or other form controls don't update the form value.

**Solutions:**

1. **Check name attribute** - Ensure `name` matches the form field:
   ```heex
   <.select id="role-select" name={@form[:role].name} value={@form[:role].value}>
   ```

2. **Check phx-change** - Form needs `phx-change` for live validation:
   ```heex
   <.simple_form for={@form} phx-change="validate" phx-submit="save">
   ```

### Dialog not opening/closing

**Symptoms:** `show_dialog`/`hide_dialog` functions don't work.

**Solutions:**

1. **Use correct module path**:
   ```heex
   <%# Wrong %>
   <.button phx-click={show_dialog("my-dialog")}>
   
   <%# Correct %>
   <.button phx-click={SutraUI.Dialog.show_dialog("my-dialog")}>
   ```

2. **Check dialog ID** - Must match exactly:
   ```heex
   <.dialog id="confirm-dialog">
   <.button phx-click={SutraUI.Dialog.show_dialog("confirm-dialog")}>
   ```

### LiveView disconnects on component interaction

**Symptoms:** Page refreshes or socket disconnects when clicking components.

**Solutions:**

1. **Check event handlers** - Ensure `phx-click` handlers exist in LiveView:
   ```elixir
   def handle_event("my_action", params, socket) do
     {:noreply, socket}
   end
   ```

2. **Prevent default on links** - Use `phx-click` instead of `onclick` for LiveView events.

### Theme variables not working

**Symptoms:** Custom CSS variables are ignored.

**Solutions:**

1. **Check variable syntax** - Use OKLCH format:
   ```css
   /* Wrong */
   --primary: #3b82f6;
   
   /* Correct */
   --primary: oklch(0.623 0.214 259.815);
   ```

2. **Check override order** - Custom variables must come after Sutra UI CSS:
   ```css
   @import "../../deps/sutra_ui/priv/static/sutra_ui.css";
   
   :root {
     --primary: oklch(0.65 0.20 145); /* This overrides */
   }
   ```

### Component tests failing

**Symptoms:** Tests can't find components or hooks.

**Solutions:**

1. **Import correctly** - Test files need explicit imports:
   ```elixir
   defmodule SutraUI.ButtonTest do
     use ComponentCase, async: true
     import SutraUI.Button
   ```

2. **Use render_component** - Not `render`:
   ```elixir
   html = render_component(&button/1, variant: "primary")
   ```

## Migration Notes

### From Phoenix 1.7 to 1.8+

1. Update dependencies in `mix.exs`
2. Update `app.js` to import colocated hooks from `phoenix-colocated/sutra_ui`
3. Remove any manual hook registrations from old `hooks.js` files - colocated hooks are now extracted automatically

### From Tailwind v3 to v4

1. Replace `tailwind.config.js` with `@source` directives in CSS
2. Update color values from HSL to OKLCH if customizing theme
3. Update any custom CSS using Tailwind's `@apply` with new syntax

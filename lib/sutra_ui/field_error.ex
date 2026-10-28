defmodule SutraUI.FieldError do
  @moduledoc false
  # One error line (icon and message) shared by `SutraUI.Input` and the pickers. Not imported
  # by `use SutraUI`, so it cannot clash with an app's own `error/1`.
  use Phoenix.Component

  def error(assigns) do
    ~H"""
    <p class="flex gap-2 items-center text-sm text-destructive">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="currentColor"
        class="size-5 shrink-0"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zM12 8.25a.75.75 0 01.75.75v3.75a.75.75 0 01-1.5 0V9a.75.75 0 01.75-.75zm0 8.25a.75.75 0 100-1.5.75.75 0 000 1.5z"
          clip-rule="evenodd"
        />
      </svg>
      {render_slot(@inner_block)}
    </p>
    """
  end
end

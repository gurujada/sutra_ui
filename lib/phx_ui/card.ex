defmodule PhxUI.Card do
  @moduledoc """
  Displays a card with header, content, and footer.

  Cards are versatile containers for grouping related content and actions.

  ## Examples

      <.card>
        <:header>
          <h2>Card Title</h2>
          <p>Card Description</p>
        </:header>
        <:content>
          <p>Card Content</p>
        </:content>
        <:footer>
          <p>Card Footer</p>
        </:footer>
      </.card>

  ## Accessibility

  - Uses semantic `<header>`, `<section>`, and `<footer>` elements
  - Consider adding appropriate headings (h2, h3) in the header slot
  """

  use Phoenix.Component

  @doc """
  Renders a card component with optional header, content, and footer.

  ## Examples

      <.card>
        <:header>
          <h2>Login to your account</h2>
          <p>Enter your details below</p>
        </:header>
        <:content>
          <form>...</form>
        </:content>
        <:footer class="flex gap-2">
          <button class="btn">Login</button>
        </:footer>
      </.card>

      # With image in content
      <.card>
        <:content class="px-0">
          <img alt="Example" src="/images/example.jpg" />
        </:content>
      </.card>
  """

  attr(:class, :any, default: nil, doc: "Additional CSS classes (string or list)")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot :header, doc: "Optional header slot with title and description" do
    attr(:class, :string, doc: "Additional CSS classes for the header")
  end

  slot :content, required: true, doc: "The main content of the card" do
    attr(:class, :string, doc: "Additional CSS classes for the content")
  end

  slot :footer, doc: "Optional footer slot" do
    attr(:class, :string, doc: "Additional CSS classes for the footer")
  end

  def card(assigns) do
    ~H"""
    <div class={["card", @class]} {@rest}>
      <%= if @header != [] do %>
        <header class={[header_slot_class(@header)]}>
          {render_slot(@header)}
        </header>
      <% end %>
      <section class={[content_slot_class(@content)]}>
        {render_slot(@content)}
      </section>
      <%= if @footer != [] do %>
        <footer class={[footer_slot_class(@footer)]}>
          {render_slot(@footer)}
        </footer>
      <% end %>
    </div>
    """
  end

  defp header_slot_class([%{class: class} | _]), do: class
  defp header_slot_class(_), do: nil

  defp content_slot_class([%{class: class} | _]), do: class
  defp content_slot_class(_), do: nil

  defp footer_slot_class([%{class: class} | _]), do: class
  defp footer_slot_class(_), do: nil
end

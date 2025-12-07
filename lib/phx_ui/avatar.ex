defmodule PhxUI.Avatar do
  @moduledoc """
  An image element with a fallback for representing the user.

  The avatar component displays user profile images with automatic fallback support.
  When an image fails to load or is not provided, it can display initials or an icon.

  ## Examples

      # Avatar with image and initials fallback
      <.avatar src="https://github.com/username.png" alt="Username" initials="UN" />

      # Avatar with just initials
      <.avatar initials="JD" />

      # Avatar with icon fallback
      <.avatar src="/avatar.jpg" alt="User">
        <:fallback>
          <.icon name="hero-user" />
        </:fallback>
      </.avatar>

      # Different sizes
      <.avatar src="/avatar.jpg" alt="User" size="sm" initials="AB" />
      <.avatar src="/avatar.jpg" alt="User" size="lg" initials="CD" />

      # Square avatar
      <.avatar src="/avatar.jpg" alt="User" shape="square" initials="EF" />

      # Avatar group
      <div class="avatar-group">
        <.avatar src="https://github.com/user1.png" alt="User 1" initials="U1" />
        <.avatar src="https://github.com/user2.png" alt="User 2" initials="U2" />
        <.avatar src="https://github.com/user3.png" alt="User 3" initials="U3" />
      </div>
  """

  use Phoenix.Component

  import PhxUI.Icon, only: [icon: 1]

  @doc """
  Renders an avatar component.
  """
  attr(:src, :string, default: nil, doc: "The image source URL")
  attr(:alt, :string, default: "", doc: "Alternative text for the image")

  attr(:initials, :string,
    default: nil,
    doc: "Fallback initials to display (1-2 characters recommended)"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg xl),
    doc: "The size of the avatar"
  )

  attr(:shape, :string,
    default: "circle",
    values: ~w(circle square),
    doc: "The shape of the avatar"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:fallback,
    doc:
      "Custom fallback content (icon, text, etc.). If not provided, initials will be used if available."
  )

  def avatar(assigns) do
    ~H"""
    <span class={["avatar", "avatar-#{@size}", "avatar-#{@shape}", @class]} {@rest}>
      <%= if @src do %>
        <img
          src={@src}
          alt={@alt}
          class="avatar-image"
          onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"
        />
      <% end %>
      <span class={["avatar-fallback", @src && "avatar-fallback-hidden"]}>
        <%= if @fallback != [] do %>
          {render_slot(@fallback)}
        <% else %>
          <%= if @initials do %>
            {@initials}
          <% else %>
            <.icon name="hero-user" />
          <% end %>
        <% end %>
      </span>
    </span>
    """
  end
end

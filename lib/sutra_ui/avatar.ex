defmodule SutraUI.Avatar do
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
          <!-- Your icon here -->
        </:fallback>
      </.avatar>

      # Different sizes
      <.avatar src="/avatar.jpg" alt="User" size="sm" initials="AB" />
      <.avatar src="/avatar.jpg" alt="User" size="lg" initials="CD" />

      # Square avatar
      <.avatar src="/avatar.jpg" alt="User" shape="square" initials="EF" />

      # Avatar group: a stack of faces with "+n" beyond `max`
      <.avatar_group
        id="reviewers"
        label="Reviewers"
        max={3}
        people={[
          %{name: "Asha Rao", src: "/asha.png"},
          %{name: "Ravi Teja"},
          %{name: "Mei Lin", initials: "ML"},
          %{name: "Sam Cole"}
        ]}
      />

  ## Avatar group

  `avatar_group/1` stacks avatars. People beyond `max` collapse to "+n". The group is one
  `role="group"` named by `label` and every name ("Reviewers: Asha Rao, Ravi Teja, ..."), so a
  screen reader hears all of them, including the hidden ones; each face also shows its name
  as a tooltip on hover. Pass an `id` (it is also used for the faces' image fallbacks, so
  `nonce` applies when you use a Content-Security-Policy).

  ## Presence

  `status` (`"online"`, `"away"`, `"offline"`; default none) adds a small dot cut into the
  avatar's edge with a ring in the background colour, in the `--success`, `--warning` and muted
  tokens, and a screen-reader word, so the state is never colour alone. SutraUI holds no
  presence logic: the app supplies the state, for example from `Phoenix.Presence`.

      <.avatar initials="AR" status="online" />
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders an avatar component.

  When `src` fails to load the fallback is shown. With an `id`, a small hook does this and
  works under a nonce-based Content-Security-Policy (pass `nonce`). Without an `id` the
  image carries an inline `onerror` handler, which such a policy blocks.
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

  attr(:status, :string,
    default: nil,
    doc:
      "Presence: a small dot at the avatar's edge plus a screen-reader word. The app supplies it (for example from `Phoenix.Presence`)"
  )

  attr(:announce_status, :boolean,
    default: true,
    doc: "Render the screen-reader word; `avatar_group` turns it off and names the status itself"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script (needs `id`)")

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
    <span
      class={["avatar", "avatar-#{@size}", "avatar-#{@shape}", @class]}
      phx-hook={@src && @rest[:id] && ".Avatar"}
      data-status={@status}
      {@rest}
    >
      <%= if @src do %>
        <img
          src={@src}
          alt={@alt}
          class="avatar-image"
          onerror={
            !@rest[:id] &&
              "this.style.display='none'; this.nextElementSibling.style.display='flex';"
          }
        />
      <% end %>
      <span class={["avatar-fallback", @src && "avatar-fallback-hidden"]}>
        <%= if @fallback != [] do %>
          {render_slot(@fallback)}
        <% else %>
          <%= if @initials do %>
            {@initials}
          <% else %>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
            </svg>
          <% end %>
        <% end %>
      </span>
      <span :if={@status} class="avatar-status" aria-hidden="true"></span>
      <span :if={@status && @announce_status} class="sr-only">{@status}</span>
      <script
        :if={@src && @rest[:id]}
        :type={ColocatedHook}
        name=".Avatar"
        runtime
        nonce={@nonce}
      >
        {
          mounted() {
            this.img = this.el.querySelector('.avatar-image');
            this.onError = () => this.showFallback();
            this.img?.addEventListener('error', this.onError);
            this.check();
          },

          updated() {
            this.img?.removeEventListener('error', this.onError);
            this.img = this.el.querySelector('.avatar-image');
            this.img?.addEventListener('error', this.onError);
            this.check();
          },

          destroyed() {
            this.img?.removeEventListener('error', this.onError);
          },

          // The image may have failed before this hook mounted.
          check() {
            if (this.img && this.img.complete && this.img.naturalWidth === 0) this.showFallback();
          },

          showFallback() {
            this.el.setAttribute('data-avatar-failed', '');
          }
        }
      </script>
    </span>
    """
  end

  @doc """
  A stack of avatars with "+n" for the people beyond `max`.

  Each person is a map with a `:name` and optional `:src`, `:initials` (default: the first
  letters of the first two words of the name) and `:status` (`"online"`, `"away"` or
  `"offline"`, shown as a dot and named in the group's accessible name: "Asha Rao (online)").
  """
  attr(:id, :string, required: true, doc: "Unique identifier")
  attr(:people, :list, required: true, doc: "Maps with `:name` and optional `:src`, `:initials`")
  attr(:max, :integer, default: 3, doc: "How many faces show before \"+n\"")
  attr(:size, :string, default: "sm", values: ~w(sm md lg xl), doc: "Size of every avatar")

  attr(:label, :string,
    default: nil,
    doc: "Accessible name of the group, e.g. \"Reviewers\"; the names follow it"
  )

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the avatars' image-fallback hooks")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  def avatar_group(assigns) do
    {shown, hidden} = Enum.split(assigns.people, max(assigns.max, 0))
    names = Enum.map_join(assigns.people, ", ", &person_label/1)

    assigns =
      assign(assigns,
        shown: Enum.with_index(shown),
        hidden: hidden,
        hidden_names: Enum.map_join(hidden, ", ", & &1.name),
        group_name: if(assigns.label, do: "#{assigns.label}: #{names}", else: names)
      )

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@group_name}
      class={["avatar-group", @class]}
      data-size={@size}
      data-total={length(@people)}
      data-hidden={length(@hidden)}
      {@rest}
    >
      <span :for={{person, index} <- @shown} title={person.name} class="avatar-group-item">
        <.avatar
          id={person[:src] && "#{@id}-#{index}"}
          nonce={@nonce}
          size={@size}
          src={person[:src]}
          alt=""
          initials={person[:initials] || initials(person.name)}
          status={person[:status]}
          announce_status={false}
        />
      </span>
      <span
        :if={@hidden != []}
        title={@hidden_names}
        class={["avatar", "avatar-#{@size}", "avatar-circle", "avatar-group-more"]}
        aria-hidden="true"
      >
        <span class="avatar-fallback">+{length(@hidden)}</span>
      </span>
    </div>
    """
  end

  defp person_label(%{status: status} = person) when status in ["online", "away", "offline"],
    do: "#{person.name} (#{status})"

  defp person_label(person), do: person.name

  defp initials(name) do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end
end

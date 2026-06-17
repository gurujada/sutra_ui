defmodule SutraUI.FileUpload do
  @moduledoc """
  A Phoenix LiveView file upload dropzone.

  This component styles Phoenix's built-in upload input. Configure uploads in
  your LiveView with `allow_upload/3`, then pass the upload config into
  `<.file_upload upload={@uploads.avatar} />`.
  """

  use Phoenix.Component

  attr(:upload, :any, default: nil, doc: "Phoenix LiveView upload config")
  attr(:label, :string, default: "Choose files", doc: "Primary label")
  attr(:description, :string, default: nil, doc: "Supporting description")
  attr(:icon, :boolean, default: true, doc: "Show upload icon")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:input_class, :any, default: nil, doc: "Additional classes for live_file_input")
  attr(:rest, :global, include: ~w(id), doc: "Additional HTML attributes")

  slot :entry do
    attr(:name, :string, doc: "File name")
    attr(:progress, :integer, doc: "Upload progress")
    attr(:status, :string, doc: "Status label")
  end

  def file_upload(assigns) do
    ~H"""
    <div class={["file-upload", @class]} {@rest}>
      <label class="file-upload-dropzone">
        <span :if={@icon} class="file-upload-icon" aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M12 3v12" />
            <path d="m17 8-5-5-5 5" />
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
          </svg>
        </span>
        <span class="file-upload-copy">
          <span class="file-upload-label">{@label}</span>
          <span :if={@description} class="file-upload-description">{@description}</span>
        </span>
        <.live_file_input :if={@upload} upload={@upload} class={["file-upload-input", @input_class]} />
      </label>
      <ul :if={@entry != []} class="file-upload-list">
        <li :for={entry <- @entry} class="file-upload-entry">
          <div class="file-upload-entry-header">
            <span>{entry[:name]}</span>
            <span :if={entry[:status]}>{entry.status}</span>
          </div>
          <div
            :if={is_integer(entry[:progress])}
            class="file-upload-progress"
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={entry.progress}
            role="progressbar"
          >
            <span style={"width: #{entry.progress}%"}></span>
          </div>
          <%= if entry[:inner_block] do %>
            {render_slot(entry)}
          <% end %>
        </li>
      </ul>
    </div>
    """
  end
end

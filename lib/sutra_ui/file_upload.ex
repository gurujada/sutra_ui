defmodule SutraUI.FileUpload do
  @moduledoc """
  A drag-and-drop file upload component built on Phoenix LiveView uploads.

  Wraps Phoenix's `allow_upload/3` with a styled dropzone, per-file progress bars,
  and file previews. Configure uploads in your LiveView, then pass the config.

  ## Examples

      # In your LiveView
      def mount(_params, _session, socket) do
        {:ok, allow_upload(socket, :attachments, accept: ~w(.pdf .png), max_entries: 5)}
      end

      # In your template
      <.file_upload upload={@uploads.attachments} label="Upload documents" />

      # With custom dropzone content
      <.file_upload upload={@uploads.photos} accept="image/*" max_files={3}>
        <:drop_content>
          Drop photos here or click to browse
        </:drop_content>
      </.file_upload>
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:upload, :any, default: nil, doc: "Phoenix LiveView upload config from allow_upload/3")
  attr(:label, :string, default: nil, doc: "Label text for the dropzone")
  attr(:description, :string, default: nil, doc: "Hint text shown below the label")
  attr(:accept, :string, default: nil, doc: "Accepted file types, e.g. 'image/*' or '.pdf,.doc'")
  attr(:max_files, :integer, default: nil, doc: "Maximum number of files")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:id, :string, default: nil, doc: "DOM id for the upload root")

  attr(:cancel_event, :string,
    default: "cancel-upload",
    doc: "Event emitted when removing a file"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:drop_content, doc: "Custom content for the dropzone. Falls back to default label/icon.")

  def file_upload(assigns) do
    ref = (assigns.upload && assigns.upload.ref) || "no-upload"
    entries = (assigns.upload && assigns.upload.entries) || []

    assigns =
      assigns
      |> assign(:ref, ref)
      |> assign(:entries, entries)
      |> assign(:dom_id, assigns.id || (assigns.upload && "#{ref}-dropzone"))

    ~H"""
    <div
      id={@dom_id}
      class={["file-upload", @class]}
      phx-hook={@upload && ".FileUpload"}
      phx-drop-target={@upload && @ref}
      data-accept={@accept}
      data-max-files={@max_files}
      {@rest}
    >
      <label class="file-upload-dropzone" phx-drop-target={@upload && @ref}>
        <div :if={@drop_content == [] && !@label} class="file-upload-default">
          <span class="file-upload-icon" aria-hidden="true">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line
                x1="12"
                x2="12"
                y1="3"
                y2="15"
              />
            </svg>
          </span>
          <span class="file-upload-copy">
            <span class="file-upload-label">Drop files here or click to browse</span>
          </span>
        </div>
        <div :if={@drop_content == [] && @label} class="file-upload-default">
          <span class="file-upload-icon" aria-hidden="true">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line
                x1="12"
                x2="12"
                y1="3"
                y2="15"
              />
            </svg>
          </span>
          <span class="file-upload-copy">
            <span class="file-upload-label">{@label}</span>
            <span :if={@description} class="file-upload-description">{@description}</span>
          </span>
        </div>
        <div :if={@drop_content != []} class="file-upload-custom">
          {render_slot(@drop_content)}
        </div>
        <.live_file_input :if={@upload} upload={@upload} class="file-upload-input" />
      </label>
      <div class="file-upload-preview" data-upload-preview>
        <div :for={entry <- @entries} class="file-upload-entry" data-entry-ref={entry.ref}>
          <div class="file-upload-entry-info">
            <span class="file-upload-entry-icon" aria-hidden="true">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z" /><polyline points="14 2 14 8 20 8" />
              </svg>
            </span>
            <span class="file-upload-entry-name">{entry.client_name}</span>
            <span class="file-upload-entry-size">{format_bytes(entry.client_size)}</span>
          </div>
          <div
            class="file-upload-entry-progress"
            role="progressbar"
            aria-valuenow={entry.progress}
            aria-valuemin="0"
            aria-valuemax="100"
          >
            <span style={"width: #{entry.progress}%"}></span>
          </div>
          <button
            type="button"
            class="file-upload-entry-remove"
            aria-label="Remove #{entry.client_name}"
            phx-click={@cancel_event}
            phx-value-ref={entry.ref}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="size-4"
              aria-hidden="true"
            >
              <path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />
            </svg>
          </button>
          <p :if={entry.invalid? && entry.errors != []} class="file-upload-entry-error">
            {entry_error(entry.errors)}
          </p>
        </div>
      </div>
    </div>

    <script :type={ColocatedHook} name=".FileUpload" runtime>
      {
        mounted() {
          this.dropzone = this.el.querySelector('.file-upload-dropzone');
          this.input = this.el.querySelector('input[type="file"]');

          if (!this.input) return;

          this.dropzone.addEventListener('dragover', (e) => {
            e.preventDefault();
            this.dropzone.classList.add('file-upload-drag-over');
          });

          this.dropzone.addEventListener('dragleave', () => {
            this.dropzone.classList.remove('file-upload-drag-over');
          });

          this.dropzone.addEventListener('drop', (e) => {
            e.preventDefault();
            this.dropzone.classList.remove('file-upload-drag-over');
          });

        }
      }
    </script>
    """
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_bytes(_), do: ""

  defp entry_error([%{reason: reason} | _]) when is_binary(reason), do: reason

  defp entry_error([%{too_large: %{max_size: max}} | _]) do
    max_mb = Float.round(max / 1_000_000, 1)
    "File exceeds #{max_mb} MB limit"
  end

  defp entry_error(_), do: "Invalid file"
end

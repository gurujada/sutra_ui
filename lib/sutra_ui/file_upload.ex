defmodule SutraUI.FileUpload do
  @moduledoc """
  A drag-and-drop file upload component built on Phoenix LiveView uploads.

  Wraps Phoenix's `allow_upload/3` with a styled dropzone, per-file progress
  bars, image thumbnails, and file previews. Configure uploads in your
  LiveView, then pass the upload config.

  ## Examples

      # In your LiveView
      def mount(_params, _session, socket) do
        {:ok,
         socket
         |> allow_upload(:documents,
           accept: ~w(.pdf .png),
           max_entries: 5,
           max_file_size: 10_000_000
         )}
      end

      # In your template
      <.form for={@form} phx-change="validate" phx-submit="save">
        <.file_upload upload={@uploads.documents} label="Upload documents" />
      </.form>

      # Image upload with thumbnails
      <.file_upload
        upload={@uploads.photos}
        label="Upload photos"
        description="JPG or PNG, max 5 files"
        thumbnail
      />

      # Custom dropzone content
      <.file_upload upload={@uploads.files}>
        <:drop_content>
          <span class="text-4xl">📁</span>
          <span>Drop your files here</span>
        </:drop_content>
      </.file_upload>

      # Custom preview content
      <.file_upload upload={@uploads.documents}>
        <:entry :let={item}>
          <div class="flex items-center justify-between gap-3">
            <span class="truncate">{item.entry.client_name}</span>
            <button
              type="button"
              phx-click={item.cancel_event}
              phx-value-upload={item.upload.name}
              phx-value-ref={item.entry.ref}
            >
              Remove
            </button>
          </div>
        </:entry>
      </.file_upload>

  ## Attributes

  * `upload` - Phoenix LiveView upload config from `allow_upload/3`.
  * `label` - Label text for the dropzone.
  * `description` - Hint text shown below the label.
  * `thumbnail` - Show image previews for image entries. Defaults to `false`.
  * `class` - Additional CSS classes.
  * `id` - Optional DOM id for the upload root. Defaults to `{ref}-dropzone`.
  * `cancel_event` - Event emitted when removing a file. Defaults to
    `"cancel-upload"`.

  Accepted file types, max entries, and max file size belong in
  `allow_upload/3`; the component reads the resulting upload config.

  ## Slots

  * `:drop_content` - Custom content for the dropzone. Falls back to the
    default icon + label/description.
  * `:entry` - Custom preview for each selected file. Receives a map with
    `entry`, `upload`, and `cancel_event`.

  ## Event Handling

  ```elixir
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("save", _params, socket) do
    consumed =
      consume_uploaded_entries(socket, :documents, fn meta, entry ->
        dest = Path.join("priv/uploads", Path.basename(entry.client_name))
        File.cp!(meta.path, dest)
        {:ok, dest}
      end)

    {:noreply, put_flash(socket, :info, "Uploaded \#{length(consumed)} files")}
  end

  def handle_event("cancel-upload", %{"upload" => upload, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, String.to_existing_atom(upload), ref)}
  end
  ```

  ## Accessibility

  - The dropzone is a `<label>` wrapping the file input — clicking anywhere
    opens the file picker.
  - The file input is visually hidden but keyboard-focusable; focus rings
    appear on the dropzone.
  - Each entry's cancel button has a descriptive `aria-label`.
  - Progress bars use `role="progressbar"` with `aria-valuenow/min/max`.
  - Error messages per entry are rendered inline.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:upload, :any, default: nil, doc: "Phoenix LiveView upload config from allow_upload/3")
  attr(:label, :string, default: nil, doc: "Label text for the dropzone")
  attr(:description, :string, default: nil, doc: "Hint text shown below the label")
  attr(:thumbnail, :boolean, default: false, doc: "Show image previews for image entries")
  attr(:accept, :any, default: nil, doc: "Deprecated. Configure accepted types in allow_upload/3")
  attr(:max_files, :any, default: nil, doc: "Deprecated. Configure max entries in allow_upload/3")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:id, :string, default: nil, doc: "DOM id for the upload root")

  attr(:cancel_event, :string,
    default: "cancel-upload",
    doc: "Event emitted when removing a file"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:drop_content, doc: "Custom content for the dropzone. Falls back to default icon + label.")
  slot(:entry, doc: "Custom preview for each selected file.")

  def file_upload(assigns) do
    ref = (assigns.upload && assigns.upload.ref) || "no-upload"
    entries = (assigns.upload && assigns.upload.entries) || []

    assigns =
      assigns
      |> assign(:ref, ref)
      |> assign(:entries, entries)
      |> assign(:hook, assigns.upload && "SutraUI.FileUpload.FileUpload")
      |> assign(:upload_errors, if(assigns.upload, do: upload_errors(assigns.upload), else: []))
      |> assign(:dom_id, assigns.id || (assigns.upload && "#{ref}-dropzone"))

    ~H"""
    <div
      id={@dom_id}
      class={["file-upload", @class]}
      phx-hook={@hook}
      phx-drop-target={@upload && @ref}
      {@rest}
    >
      <label class="file-upload-dropzone" phx-drop-target={@upload && @ref}>
        <%= if @drop_content != [] do %>
          <div class="file-upload-custom">
            {render_slot(@drop_content)}
          </div>
        <% else %>
          <div class="file-upload-default">
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
              <span class="file-upload-label">
                {@label || "Drop files here or click to browse"}
              </span>
              <span :if={@description} class="file-upload-description">
                {@description}
              </span>
            </span>
          </div>
        <% end %>
        <.live_file_input :if={@upload} upload={@upload} class="file-upload-input" />
      </label>
      <p :for={error <- @upload_errors} class="file-upload-entry-error">
        {entry_error(error)}
      </p>
      <div class="file-upload-preview" data-upload-preview>
        <div :for={entry <- @entries} class="file-upload-entry" data-entry-ref={entry.ref}>
          <%= if @entry != [] do %>
            {render_slot(@entry, %{entry: entry, upload: @upload, cancel_event: @cancel_event})}
          <% else %>
            <div class="file-upload-entry-row">
              <.entry_thumbnail :if={@thumbnail && image_entry?(entry)} entry={entry} />
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
              <div class="file-upload-entry-info">
                <span class="file-upload-entry-name">{entry.client_name}</span>
                <span class="file-upload-entry-size">{format_bytes(entry.client_size)}</span>
              </div>
              <button
                type="button"
                class="file-upload-entry-remove"
                aria-label={"Remove #{entry.client_name}"}
                phx-click={@cancel_event}
                phx-value-upload={@upload.name}
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
                  <path d="M18 6 6 18" /><path d="m6 6 12 12" />
                </svg>
              </button>
            </div>
            <div
              class="file-upload-entry-progress"
              role="progressbar"
              aria-valuenow={entry.progress}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-label={"Uploading #{entry.client_name}"}
            >
              <span style={"width: #{entry.progress}%"}></span>
            </div>
            <p :for={error <- upload_errors(@upload, entry)} class="file-upload-entry-error">
              {entry_error(error)}
            </p>
          <% end %>
        </div>
      </div>
    </div>

    <script :type={ColocatedHook} name=".FileUpload" runtime>
      {
        mounted() {
          this.dropzone = this.el.querySelector('.file-upload-dropzone');
          if (!this.dropzone) return;

          // Counter to handle dragleave firing on child elements
          this.dragCounter = 0;

          this.onDragEnter = (e) => {
            e.preventDefault();
            this.dragCounter++;
            this.dropzone.classList.add('file-upload-drag-over');
          };

          this.onDragOver = (e) => {
            e.preventDefault();
          };

          this.onDragLeave = (e) => {
            e.preventDefault();
            this.dragCounter--;
            if (this.dragCounter <= 0) {
              this.dragCounter = 0;
              this.dropzone.classList.remove('file-upload-drag-over');
            }
          };

          this.onDrop = (e) => {
            e.preventDefault();
            this.dragCounter = 0;
            this.dropzone.classList.remove('file-upload-drag-over');
          };

          this.dropzone.addEventListener('dragenter', this.onDragEnter);
          this.dropzone.addEventListener('dragover', this.onDragOver);
          this.dropzone.addEventListener('dragleave', this.onDragLeave);
          this.dropzone.addEventListener('drop', this.onDrop);
        },

        destroyed() {
          if (!this.dropzone) return;
          this.dropzone.removeEventListener('dragenter', this.onDragEnter);
          this.dropzone.removeEventListener('dragover', this.onDragOver);
          this.dropzone.removeEventListener('dragleave', this.onDragLeave);
          this.dropzone.removeEventListener('drop', this.onDrop);
        }
      }
    </script>
    """
  end

  attr(:entry, :any, required: true, doc: "Phoenix upload entry")

  defp entry_thumbnail(assigns) do
    ~H"""
    <div class="file-upload-entry-thumb" aria-hidden="true">
      <.live_img_preview entry={@entry} />
    </div>
    """
  end

  defp image_entry?(entry) do
    entry
    |> Map.get(:client_type, "")
    |> to_string()
    |> String.starts_with?("image/")
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_bytes(_), do: ""

  defp entry_error(:too_large), do: "File exceeds size limit"
  defp entry_error(:too_many_files), do: "Too many files selected"
  defp entry_error(:not_accepted), do: "File type not accepted"
  defp entry_error(:external_client_failure), do: "Upload failed"
  defp entry_error({:writer_failure, _reason}), do: "Upload failed"
  defp entry_error(reason) when is_binary(reason), do: reason

  defp entry_error(reason) when is_atom(reason) do
    reason
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp entry_error([%{reason: reason} | _]) when is_binary(reason), do: reason

  defp entry_error([%{too_large: %{max_size: max}} | _]) do
    max_mb = Float.round(max / 1_000_000, 1)
    "File exceeds #{max_mb} MB limit"
  end

  defp entry_error([%{not_accepted: %{accept: accept}} | _]) do
    "File type not accepted. Allowed: #{accept}"
  end

  defp entry_error(_), do: "Invalid file"
end

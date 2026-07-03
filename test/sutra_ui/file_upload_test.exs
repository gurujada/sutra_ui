defmodule SutraUI.FileUploadTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.FileUpload
  alias Phoenix.LiveView.{UploadConfig, UploadEntry}

  describe "file_upload/1" do
    test "renders dropzone structure" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil} />|)
      assert html =~ "file-upload"
      assert html =~ "file-upload-dropzone"
    end

    test "renders default label when no custom content" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil} />|)
      assert html =~ "Drop files here"
    end

    test "renders custom label" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<FileUpload.file_upload upload={nil} label="Upload docs" description="PDF only" />|
        )

      assert html =~ "Upload docs"
    end

    test "renders custom drop content" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil}>
  <:drop_content><span class="my-content">Drag here</span></:drop_content>
</FileUpload.file_upload>|)
      assert html =~ "my-content"
    end

    test "does not render file input without an upload config" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil} />|)
      refute html =~ "file-upload-input"
    end

    test "does not duplicate allow_upload options as root attributes" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil} accept="image/*" />|)
      refute html =~ ~s(accept="image/*")
      refute html =~ ~s(data-accept="image/*")
    end

    test "does not attach upload hook without an upload config" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload upload={nil} />|)
      refute html =~ ~s(phx-hook=".FileUpload")
      refute html =~ ~s(phx-hook="SutraUI.FileUpload.FileUpload")
    end

    test "uses caller-provided id" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload id="attachments" upload={nil} />|)
      assert html =~ ~s(id="attachments")
    end

    test "renders live upload entries and cancel metadata" do
      upload = %UploadConfig{
        name: :avatar,
        ref: "phx-avatar",
        entries: [
          %UploadEntry{
            ref: "entry-1",
            client_name: "avatar.png",
            client_size: 42_000,
            client_type: "image/png",
            progress: 35
          }
        ],
        errors: [{"entry-1", :too_large}]
      }

      assigns = %{upload: upload}

      html = rendered_to_string(~H|<FileUpload.file_upload upload={@upload} />|)

      assert html =~ "avatar.png"
      assert html =~ "42.0 KB"
      assert html =~ ~s(phx-hook="SutraUI.FileUpload.FileUpload")
      assert html =~ ~s(phx-value-upload="avatar")
      assert html =~ ~s(phx-value-ref="entry-1")
      assert html =~ ~s(aria-valuenow="35")
      assert html =~ "File exceeds size limit"
    end

    test "renders custom entry preview slot" do
      upload = %UploadConfig{
        name: :documents,
        ref: "phx-docs",
        entries: [
          %UploadEntry{ref: "entry-1", client_name: "report.pdf", client_size: 1200, progress: 10}
        ]
      }

      assigns = %{upload: upload}

      html =
        rendered_to_string(~H"""
        <FileUpload.file_upload upload={@upload}>
          <:entry :let={item}>
            <div class="custom-entry">{item.entry.client_name}:{item.cancel_event}</div>
          </:entry>
        </FileUpload.file_upload>
        """)

      assert html =~ "custom-entry"
      assert html =~ "report.pdf:cancel-upload"
      refute html =~ "file-upload-entry-progress"
    end
  end
end

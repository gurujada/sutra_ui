defmodule SutraUI.FileUploadTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.FileUpload

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
    end

    test "uses caller-provided id" do
      assigns = %{}
      html = rendered_to_string(~H|<FileUpload.file_upload id="attachments" upload={nil} />|)
      assert html =~ ~s(id="attachments")
    end
  end
end

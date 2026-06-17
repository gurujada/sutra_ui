defmodule SutraUI.FileUploadTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.FileUpload

  test "renders dropzone copy without upload config" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <FileUpload.file_upload label="Upload files" description="PDF or PNG" />
      """)

    assert html =~ "file-upload"
    assert html =~ "Upload files"
    assert html =~ "PDF or PNG"
    refute html =~ "file-upload-input"
  end

  test "renders entry progress" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <FileUpload.file_upload>
        <:entry name="invoice.pdf" progress={64} status="Uploading" />
      </FileUpload.file_upload>
      """)

    assert html =~ "invoice.pdf"
    assert html =~ "Uploading"
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-valuenow="64")
    assert html =~ "width: 64%"
  end
end

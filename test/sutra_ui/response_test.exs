defmodule SutraUI.ResponseTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Response

  describe "response/1" do
    test "renders plain text by default" do
      assigns = %{value: "Hello\nworld"}

      html =
        rendered_to_string(~H"""
        <Response.response value={@value} />
        """)

      assert html =~ "response"
      assert html =~ "response-text"
      assert html =~ "Hello"
      assert html =~ "world"
      assert html =~ ~s(data-format="text")
      assert html =~ ~s(data-reveal="chunk")
      assert html =~ ~r/<span[^>]*class="response-text"[^>]*>Hello\nworld<\/span>/
    end

    test "renders streamed markdown with MDEx" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="**Install" format="markdown" streaming />
        """)

      assert html =~ "response-markdown"
      assert html =~ "<strong>Install</strong>"
      assert html =~ ~s(data-streaming="true")
      assert html =~ ~s(aria-live="polite")
      assert html =~ ~s(aria-busy="true")
      assert html =~ "response-cursor"
    end

    test "renders animated reveal hook for text responses with an id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response id="answer" value="Loading" streaming reveal="word" />
        """)

      assert html =~ ~s(id="answer")
      assert html =~ ~s(data-reveal="word")
      assert html =~ ~s(phx-hook="SutraUI.Response.Response")
      assert html =~ ~s(data-response-content)
    end

    test "does not attach reveal hook without a stable id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="Loading" streaming reveal="character" />
        """)

      assert html =~ ~s(data-reveal="character")
      refute html =~ ~s(phx-hook="SutraUI.Response.Response")
    end

    test "keeps markdown reveal chunk-rendered" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response
          id="markdown-answer"
          value="**Loading**"
          format="markdown"
          streaming
          reveal="word"
        />
        """)

      assert html =~ "response-markdown"
      assert html =~ ~s(data-reveal="word")
      refute html =~ ~s(phx-hook="SutraUI.Response.Response")
    end

    test "sanitizes markdown html by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="<em>safe</em> <script>alert(1)</script> **ok**" format="markdown" />
        """)

      assert html =~ "safe"
      assert html =~ "<strong>ok</strong>"
      refute html =~ "<script>"
    end

    test "can render trusted markdown without sanitizing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="<mark>trusted</mark>" format="markdown" sanitize={false} />
        """)

      assert html =~ "<mark>trusted</mark>"
    end

    test "renders custom slot content when no value is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response>
          <p>Custom body</p>
        </Response.response>
        """)

      assert html =~ "response-content"
      assert html =~ "<p>Custom body</p>"
    end

    test "does not override explicit aria-live" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="Loading" streaming aria-live="assertive" />
        """)

      assert html =~ ~s(aria-live="assertive")
      refute html =~ ~s(aria-live="polite")
    end

    test "passes classes to the response root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Response.response value="Styled" class="text-muted-foreground" />
        """)

      assert html =~ "text-muted-foreground"
    end
  end
end

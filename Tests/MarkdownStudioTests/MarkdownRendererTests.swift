import Testing
@testable import MarkdownStudio

struct MarkdownRendererTests {
    @Test func rendersCommonMarkdownAndEscapesHTML() {
        let markdown = """
        # 标题

        **粗体** 和 *斜体*，还有 `code`.

        - 第一项
        - 第二项

        <script>alert("x")</script>
        """

        let html = MarkdownRenderer.render(markdown)

        #expect(html.contains("<h1>标题</h1>"))
        #expect(html.contains("<strong>粗体</strong>"))
        #expect(html.contains("<em>斜体</em>"))
        #expect(html.contains("<code>code</code>"))
        #expect(html.contains("<ul>"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }

    @Test func rendersLinksQuotesCodeBlocksAndTasks() {
        let markdown = """
        > 引用

        [OpenAI](https://openai.com)

        - [x] 完成
        - [ ] 待办

        ```swift
        let value = 1 < 2
        ```
        """

        let html = MarkdownRenderer.render(markdown)

        #expect(html.contains("<blockquote>"))
        #expect(html.contains("href=\"https://openai.com\""))
        #expect(html.contains("type=\"checkbox\" checked disabled"))
        #expect(html.contains("type=\"checkbox\" disabled"))
        #expect(html.contains("<pre><code class=\"language-swift\">"))
        #expect(html.contains("1 &lt; 2"))
    }

    @Test func rejectsUnsafeLinkSchemes() {
        let html = MarkdownRenderer.render("[危险](javascript:alert(1))")
        #expect(!html.contains("href="))
        #expect(html.contains("危险"))
    }
}

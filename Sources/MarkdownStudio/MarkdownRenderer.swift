import Foundation

enum MarkdownRenderer {
    static func render(_ markdown: String) -> String {
        var output: [String] = []
        var paragraph: [String] = []
        var listItems: [String] = []
        var quoteLines: [String] = []
        var codeLines: [String] = []
        var codeLanguage = ""
        var inCodeBlock = false

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            output.append("<p>\(inline(paragraph.joined(separator: "\n")).replacingOccurrences(of: "\n", with: "<br>"))</p>")
            paragraph.removeAll()
        }

        func flushList() {
            guard !listItems.isEmpty else { return }
            output.append("<ul>\(listItems.joined())</ul>")
            listItems.removeAll()
        }

        func flushQuote() {
            guard !quoteLines.isEmpty else { return }
            output.append("<blockquote>\(inline(quoteLines.joined(separator: "<br>")))</blockquote>")
            quoteLines.removeAll()
        }

        func flushCode() {
            let languageClass = codeLanguage.isEmpty ? "" : " class=\"language-\(escapeAttribute(codeLanguage))\""
            output.append("<pre><code\(languageClass)>\(escape(codeLines.joined(separator: "\n")))</code></pre>")
            codeLines.removeAll()
            codeLanguage = ""
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            if rawLine.hasPrefix("```") {
                if inCodeBlock {
                    flushCode()
                } else {
                    flushParagraph()
                    flushList()
                    flushQuote()
                    codeLanguage = String(rawLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                codeLines.append(rawLine)
                continue
            }

            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
                flushList()
                flushQuote()
                continue
            }

            if let heading = headingParts(line) {
                flushParagraph()
                flushList()
                flushQuote()
                output.append("<h\(heading.level)>\(inline(heading.text))</h\(heading.level)>")
            } else if line == "---" || line == "***" || line == "___" {
                flushParagraph()
                flushList()
                flushQuote()
                output.append("<hr>")
            } else if line.hasPrefix(">") {
                flushParagraph()
                flushList()
                quoteLines.append(String(line.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                flushParagraph()
                flushQuote()
                let item = String(line.dropFirst(2))
                listItems.append("<li>\(taskItem(item))</li>")
            } else {
                flushList()
                flushQuote()
                paragraph.append(line)
            }
        }

        if inCodeBlock { flushCode() }
        flushParagraph()
        flushList()
        flushQuote()
        return output.joined(separator: "\n")
    }

    static func page(for markdown: String) -> String {
        """
        <!doctype html>
        <html lang="zh-CN"><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        :root { color-scheme: light dark; }
        body { max-width: 820px; margin: 0 auto; padding: 44px 52px 80px;
          font: 16px/1.75 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
          color: CanvasText; background: Canvas; overflow-wrap: break-word; }
        h1,h2,h3,h4,h5,h6 { line-height: 1.28; margin: 1.5em 0 .55em; }
        h1 { font-size: 2em; border-bottom: 1px solid color-mix(in srgb, CanvasText 18%, transparent); padding-bottom: .3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid color-mix(in srgb, CanvasText 12%, transparent); padding-bottom: .25em; }
        p { margin: .9em 0; } a { color: #087fe7; }
        code { font: .9em ui-monospace, SFMono-Regular, Menlo, monospace; background: color-mix(in srgb, CanvasText 8%, transparent); padding: .15em .35em; border-radius: 5px; }
        pre { background: color-mix(in srgb, CanvasText 7%, transparent); padding: 18px; border-radius: 10px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { margin: 1em 0; padding: .1em 1em; border-left: 4px solid #8b8b8b; color: color-mix(in srgb, CanvasText 72%, transparent); }
        li { margin: .25em 0; } input[type=checkbox] { margin-right: .5em; }
        hr { border: 0; border-top: 1px solid color-mix(in srgb, CanvasText 18%, transparent); margin: 2em 0; }
        </style></head><body>\(render(markdown))</body></html>
        """
    }

    private static func headingParts(_ line: String) -> (level: Int, text: String)? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(count), line.dropFirst(count).first == " " else { return nil }
        return (count, String(line.dropFirst(count + 1)))
    }

    private static func taskItem(_ item: String) -> String {
        if item.hasPrefix("[x] ") || item.hasPrefix("[X] ") {
            return "<input type=\"checkbox\" checked disabled>\(inline(String(item.dropFirst(4))))"
        }
        if item.hasPrefix("[ ] ") {
            return "<input type=\"checkbox\" disabled>\(inline(String(item.dropFirst(4))))"
        }
        return inline(item)
    }

    private static func inline(_ input: String) -> String {
        var value = escape(input)
        value = replace(#"`([^`\n]+)`"#, in: value, with: "<code>$1</code>")
        value = replace(#"\[([^\]]+)\]\(([^)\s]+)\)"#, in: value) { match in
            let label = match[1]
            let destination = match[2]
            guard safeLink(destination) else { return label }
            return "<a href=\"\(escapeAttribute(destination))\">\(label)</a>"
        }
        value = replace(#"\*\*([^*\n]+)\*\*"#, in: value, with: "<strong>$1</strong>")
        value = replace(#"__([^_\n]+)__"#, in: value, with: "<strong>$1</strong>")
        value = replace(#"(?<!\*)\*([^*\n]+)\*(?!\*)"#, in: value, with: "<em>$1</em>")
        value = replace(#"~~([^~\n]+)~~"#, in: value, with: "<del>$1</del>")
        return value
    }

    private static func safeLink(_ destination: String) -> Bool {
        guard let components = URLComponents(string: destination) else { return false }
        guard let scheme = components.scheme?.lowercased() else { return true }
        return ["http", "https", "mailto"].contains(scheme)
    }

    private static func replace(_ pattern: String, in input: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }

    private static func replace(_ pattern: String, in input: String, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        var result = input
        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        for match in matches.reversed() {
            let groups = (0..<match.numberOfRanges).map { index -> String in
                guard let range = Range(match.range(at: index), in: input) else { return "" }
                return String(input[range])
            }
            guard let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: transform(groups))
        }
        return result
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func escapeAttribute(_ value: String) -> String {
        escape(value).replacingOccurrences(of: "'", with: "&#39;")
    }
}

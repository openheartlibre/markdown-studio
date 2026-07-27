(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.Markdown = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  function escapeHtml(value) {
    return value
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function inline(value) {
    return escapeHtml(value)
      .replace(/`([^`\n]+)`/g, "<code>$1</code>")
      .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2">$1</a>')
      .replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>")
      .replace(/__([^_\n]+)__/g, "<strong>$1</strong>")
      .replace(/(?<!\*)\*([^*\n]+)\*(?!\*)/g, "<em>$1</em>")
      .replace(/~~([^~\n]+)~~/g, "<del>$1</del>");
  }

  function render(markdown) {
    const lines = markdown.split(/\r?\n/);
    const output = [];
    let paragraph = [];
    let list = [];
    let code = [];
    let inCode = false;

    const flushParagraph = () => {
      if (paragraph.length) output.push(`<p>${inline(paragraph.join("\n")).replaceAll("\n", "<br>")}</p>`);
      paragraph = [];
    };
    const flushList = () => {
      if (list.length) output.push(`<ul>${list.join("")}</ul>`);
      list = [];
    };
    const flushCode = () => {
      output.push(`<pre><code>${escapeHtml(code.join("\n"))}</code></pre>`);
      code = [];
    };

    for (const raw of lines) {
      if (raw.startsWith("```")) {
        if (inCode) flushCode();
        else {
          flushParagraph();
          flushList();
        }
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        code.push(raw);
        continue;
      }
      const line = raw.trim();
      if (!line) {
        flushParagraph();
        flushList();
      } else if (/^#{1,6} /.test(line)) {
        flushParagraph();
        flushList();
        const level = line.match(/^#+/)[0].length;
        output.push(`<h${level}>${inline(line.slice(level + 1))}</h${level}>`);
      } else if (/^[-*+] /.test(line)) {
        flushParagraph();
        list.push(`<li>${inline(line.slice(2))}</li>`);
      } else if (line.startsWith(">")) {
        flushParagraph();
        flushList();
        output.push(`<blockquote>${inline(line.slice(1).trim())}</blockquote>`);
      } else {
        paragraph.push(line);
      }
    }
    if (inCode) flushCode();
    flushParagraph();
    flushList();
    return output.join("\n");
  }

  return { render };
});

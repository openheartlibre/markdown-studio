const test = require("node:test");
const assert = require("node:assert/strict");
const { render } = require("../renderer/markdown");

test("renders headings, emphasis, and lists", () => {
  const html = render("# Title\n\n**bold**\n\n- one\n- two");
  assert.match(html, /<h1>Title<\/h1>/);
  assert.match(html, /<strong>bold<\/strong>/);
  assert.match(html, /<ul><li>one<\/li><li>two<\/li><\/ul>/);
});

test("escapes raw HTML", () => {
  const html = render("<script>alert(1)</script>");
  assert.doesNotMatch(html, /<script>/);
  assert.match(html, /&lt;script&gt;/);
});

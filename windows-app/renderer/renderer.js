const editor = document.querySelector("#editor");
const rendered = document.querySelector("#rendered");
const editButton = document.querySelector("#edit");
const previewButton = document.querySelector("#preview");
const zoomValue = document.querySelector("#zoom-value");
let currentName = "Untitled.md";
let dirty = false;
let zoom = 1;
let previewMode = true;

function updateTitle() {
  document.title = `${dirty ? "● " : ""}${currentName} — Markdown Studio`;
}

function renderPreview() {
  rendered.innerHTML = Markdown.render(editor.value);
}

function setMode(preview) {
  previewMode = preview;
  editor.classList.toggle("hidden", preview);
  rendered.classList.toggle("hidden", !preview);
  editButton.classList.toggle("active", !preview);
  previewButton.classList.toggle("active", preview);
  if (preview) renderPreview();
  else editor.focus();
}

function setZoom(value) {
  zoom = Math.min(2.5, Math.max(0.5, value));
  rendered.style.fontSize = `${16 * zoom}px`;
  zoomValue.textContent = `${Math.round(zoom * 100)}%`;
}

async function save(saveAs = false) {
  const result = await window.markdownStudio.save(editor.value, saveAs);
  if (!result.canceled) {
    currentName = result.name;
    dirty = false;
    window.markdownStudio.updateState({ dirty, empty: editor.value.length === 0 });
    updateTitle();
  }
}

editor.addEventListener("input", () => {
  dirty = true;
  window.markdownStudio.updateState({ dirty, empty: editor.value.length === 0 });
  updateTitle();
});
editButton.addEventListener("click", () => setMode(false));
previewButton.addEventListener("click", () => setMode(true));
document.querySelector("#open").addEventListener("click", () => window.markdownStudio.open());
document.querySelector("#save").addEventListener("click", () => save(false));
document.querySelector("#zoom-in").addEventListener("click", () => setZoom(zoom + 0.1));
document.querySelector("#zoom-out").addEventListener("click", () => setZoom(zoom - 0.1));

window.markdownStudio.onLoaded(({ text, name }) => {
  editor.value = text;
  currentName = name;
  dirty = false;
  updateTitle();
  setMode(true);
});
window.markdownStudio.onCommand("save", () => save(false));
window.markdownStudio.onCommand("save-as", () => save(true));
window.markdownStudio.onCommand("toggle-preview", () => setMode(!previewMode));

updateTitle();
setMode(true);

const { app, BrowserWindow, dialog, ipcMain, Menu } = require("electron");
const fs = require("node:fs/promises");
const path = require("node:path");

const windows = new Map();

function markdownPathFromArgs(args) {
  return args.find((arg) => /\.(md|markdown|txt|text)$/i.test(arg) && !arg.startsWith("--"));
}

function createWindow(filePath = null) {
  const window = new BrowserWindow({
    width: 1080,
    height: 760,
    minWidth: 640,
    minHeight: 440,
    title: "Markdown Studio",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  windows.set(window.id, { window, filePath: null, dirty: false, empty: true });
  window.on("closed", () => windows.delete(window.id));
  window.loadFile(path.join(__dirname, "renderer", "index.html"));
  window.webContents.once("did-finish-load", async () => {
    if (filePath) await loadFileIntoWindow(window, filePath);
  });
  return window;
}

async function loadFileIntoWindow(window, filePath) {
  try {
    const text = await fs.readFile(filePath, "utf8");
    const state = windows.get(window.id);
    if (!state) return;
    Object.assign(state, { filePath, dirty: false, empty: text.length === 0 });
    window.webContents.send("document:loaded", {
      text,
      filePath,
      name: path.basename(filePath)
    });
  } catch (error) {
    dialog.showErrorBox("Unable to Open File", error.message);
  }
}

function targetWindowForFirstOpen() {
  if (windows.size !== 1) return null;
  const state = [...windows.values()][0];
  return state.filePath === null && !state.dirty && state.empty ? state.window : null;
}

async function openPaths(filePaths) {
  for (const [index, filePath] of filePaths.entries()) {
    const reusable = index === 0 ? targetWindowForFirstOpen() : null;
    if (reusable) await loadFileIntoWindow(reusable, filePath);
    else createWindow(filePath);
  }
}

function buildMenu() {
  const template = [
    {
      label: "File",
      submenu: [
        { label: "New Window", accelerator: "CmdOrCtrl+N", click: () => createWindow() },
        {
          label: "Open…",
          accelerator: "CmdOrCtrl+O",
          click: async () => {
            const result = await dialog.showOpenDialog({
              properties: ["openFile", "multiSelections"],
              filters: [
                { name: "Markdown and Text", extensions: ["md", "markdown", "txt", "text"] }
              ]
            });
            if (!result.canceled) await openPaths(result.filePaths);
          }
        },
        { type: "separator" },
        {
          label: "Save",
          accelerator: "CmdOrCtrl+S",
          click: (_item, window) => window?.webContents.send("command:save")
        },
        {
          label: "Save As…",
          accelerator: "CmdOrCtrl+Shift+S",
          click: (_item, window) => window?.webContents.send("command:save-as")
        },
        { type: "separator" },
        { role: "quit" }
      ]
    },
    { role: "editMenu" },
    {
      label: "View",
      submenu: [
        {
          label: "Toggle Markdown Preview",
          accelerator: "CmdOrCtrl+Shift+V",
          click: (_item, window) => window?.webContents.send("command:toggle-preview")
        },
        { role: "zoomIn" },
        { role: "zoomOut" },
        { role: "resetZoom" }
      ]
    }
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

ipcMain.handle("document:open-dialog", async () => {
  const result = await dialog.showOpenDialog({
    properties: ["openFile", "multiSelections"],
    filters: [
      { name: "Markdown and Text", extensions: ["md", "markdown", "txt", "text"] }
    ]
  });
  if (!result.canceled) await openPaths(result.filePaths);
});

ipcMain.handle("document:save", async (event, { text, saveAs }) => {
  const window = BrowserWindow.fromWebContents(event.sender);
  const state = window && windows.get(window.id);
  if (!window || !state) return { canceled: true };

  let destination = saveAs ? null : state.filePath;
  if (!destination) {
    const result = await dialog.showSaveDialog(window, {
      defaultPath: state.filePath || "Untitled.md",
      filters: [
        { name: "Markdown and Text", extensions: ["md", "markdown", "txt", "text"] }
      ]
    });
    if (result.canceled || !result.filePath) return { canceled: true };
    destination = result.filePath;
  }

  await fs.writeFile(destination, text, "utf8");
  Object.assign(state, { filePath: destination, dirty: false, empty: text.length === 0 });
  return { canceled: false, filePath: destination, name: path.basename(destination) };
});

ipcMain.on("document:state", (event, stateUpdate) => {
  const window = BrowserWindow.fromWebContents(event.sender);
  const state = window && windows.get(window.id);
  if (!window || !state) return;
  state.dirty = Boolean(stateUpdate.dirty);
  state.empty = Boolean(stateUpdate.empty);
  window.setDocumentEdited(state.dirty);
});

app.on("second-instance", (_event, argv) => {
  const filePath = markdownPathFromArgs(argv);
  if (filePath) openPaths([filePath]);
  else createWindow();
});

app.whenReady().then(() => {
  if (!app.requestSingleInstanceLock()) {
    app.quit();
    return;
  }
  buildMenu();
  createWindow(markdownPathFromArgs(process.argv));
});

app.on("window-all-closed", () => app.quit());

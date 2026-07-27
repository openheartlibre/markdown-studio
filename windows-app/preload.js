const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("markdownStudio", {
  open: () => ipcRenderer.invoke("document:open-dialog"),
  save: (text, saveAs = false) => ipcRenderer.invoke("document:save", { text, saveAs }),
  updateState: (state) => ipcRenderer.send("document:state", state),
  onLoaded: (callback) => ipcRenderer.on("document:loaded", (_event, value) => callback(value)),
  onCommand: (name, callback) => ipcRenderer.on(`command:${name}`, callback)
});

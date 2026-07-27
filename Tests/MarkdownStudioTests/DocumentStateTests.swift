import Foundation
import Testing
@testable import MarkdownStudio

struct DocumentStateTests {
    @Test func editingMarksDocumentDirtyAndSavingClearsIt() throws {
        let state = DocumentState()
        #expect(!state.isDirty)

        state.updateText("# 新文档")
        #expect(state.isDirty)

        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let file = folder.appendingPathComponent("笔记.md")
        try state.save(to: file)

        #expect(!state.isDirty)
        #expect(try String(contentsOf: file, encoding: .utf8) == "# 新文档")
        #expect(state.fileURL == file)
    }

    @Test func openReadsUTF8Markdown() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let file = folder.appendingPathComponent("readme.markdown")
        try "你好，Markdown".write(to: file, atomically: true, encoding: .utf8)

        let state = DocumentState()
        try state.open(file)

        #expect(state.text == "你好，Markdown")
        #expect(!state.isDirty)
        #expect(state.fileURL == file)
    }

    @Test func openAndSavePlainTextDocument() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let file = folder.appendingPathComponent("notes.txt")
        try "Plain text notes".write(to: file, atomically: true, encoding: .utf8)

        let state = DocumentState()
        try state.open(file)
        state.updateText("Updated plain text")
        try state.save()

        #expect(state.fileURL?.pathExtension == "txt")
        #expect(try String(contentsOf: file, encoding: .utf8) == "Updated plain text")
        #expect(!state.isDirty)
    }
}

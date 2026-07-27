import Foundation

final class DocumentState {
    private(set) var text = ""
    private(set) var fileURL: URL?
    private(set) var isDirty = false

    var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled.md"
    }

    func updateText(_ newText: String) {
        guard newText != text else { return }
        text = newText
        isDirty = true
    }

    func newDocument() {
        text = ""
        fileURL = nil
        isDirty = false
    }

    func open(_ url: URL) throws {
        text = try String(contentsOf: url, encoding: .utf8)
        fileURL = url
        isDirty = false
    }

    func save(to url: URL? = nil) throws {
        guard let destination = url ?? fileURL else {
            throw DocumentError.missingDestination
        }
        try text.write(to: destination, atomically: true, encoding: .utf8)
        fileURL = destination
        isDirty = false
    }
}

enum DocumentError: LocalizedError {
    case missingDestination

    var errorDescription: String? {
        "No save location has been selected."
    }
}

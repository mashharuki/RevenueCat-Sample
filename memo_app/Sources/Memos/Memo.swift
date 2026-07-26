import Foundation

/// Client-side mirror of the backend's `MemoDto` (design.md "API Data Transfer" contract).
/// `userId` is intentionally absent — the API never returns another user's memos.
struct Memo: Codable, Identifiable, Equatable {
  let id: String
  let content: String
  let createdAt: Date
  let updatedAt: Date
}

extension Memo {
  /// The backend serializes timestamps with `Date().toISOString()`, which always includes
  /// fractional seconds — `ISO8601DateFormatter`'s default options reject that format, so a
  /// dedicated formatter is required instead of `.withInternetDateTime` alone.
  static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  /// Decoder configured to parse `createdAt`/`updatedAt` using the formatter above.
  static var jsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let string = try container.decode(String.self)
      guard let date = Memo.iso8601WithFractionalSeconds.date(from: string) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(string)")
      }
      return date
    }
    return decoder
  }
}

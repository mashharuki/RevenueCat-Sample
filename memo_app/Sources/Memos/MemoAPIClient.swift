import FirebaseAuth
import Foundation

/// Errors returned by `MemoAPIClienting`. Kept distinct from HTTP status codes so callers can
/// switch on meaning rather than numbers, and so network failures are never silently swallowed
/// (design.md Requirement 5.2).
enum MemoAPIError: Error {
  case unauthorized
  case forbidden
  case notFound
  case validation(message: String)
  case limitReached(limit: Int)
  case network(Error)
  case server(statusCode: Int)
  case decoding(Error)
}

protocol MemoAPIClienting {
  func listMemos() async -> Result<[Memo], MemoAPIError>
  func createMemo(content: String) async -> Result<Memo, MemoAPIError>
  func updateMemo(id: String, content: String) async -> Result<Memo, MemoAPIError>
  func deleteMemo(id: String) async -> Result<Void, MemoAPIError>
}

/// HTTP client for the `api/` backend's `/api/memos` endpoints. Attaches a fresh Firebase ID
/// token to every request (tokens are short-lived, so this must not be cached across calls).
struct MemoAPIClient: MemoAPIClienting {
  /// Deployed Worker URL (see .kiro/specs/memo-app/tasks.md Implementation Notes 1.5).
  static let defaultBaseURL = URL(string: "https://memo-app-api.avp-104-106-107-a78.workers.dev")!

  private let baseURL: URL
  private let session: URLSession
  private let idTokenProvider: () async throws -> String

  init(
    baseURL: URL = MemoAPIClient.defaultBaseURL,
    session: URLSession = .shared,
    idTokenProvider: @escaping () async throws -> String = MemoAPIClient.currentFirebaseIDToken
  ) {
    self.baseURL = baseURL
    self.session = session
    self.idTokenProvider = idTokenProvider
  }

  static func currentFirebaseIDToken() async throws -> String {
    guard let user = Auth.auth().currentUser else {
      throw MemoAPIError.unauthorized
    }
    return try await user.getIDToken()
  }

  func listMemos() async -> Result<[Memo], MemoAPIError> {
    await request(path: "/api/memos", method: "GET", body: Optional<ContentBody>.none)
      .flatMap { decode([Memo].self, from: $0) }
  }

  func createMemo(content: String) async -> Result<Memo, MemoAPIError> {
    await request(path: "/api/memos", method: "POST", body: ContentBody(content: content))
      .flatMap { decode(Memo.self, from: $0) }
  }

  func updateMemo(id: String, content: String) async -> Result<Memo, MemoAPIError> {
    await request(path: "/api/memos/\(id)", method: "PATCH", body: ContentBody(content: content))
      .flatMap { decode(Memo.self, from: $0) }
  }

  func deleteMemo(id: String) async -> Result<Void, MemoAPIError> {
    await request(path: "/api/memos/\(id)", method: "DELETE", body: Optional<ContentBody>.none)
      .map { _ in () }
  }

  // MARK: - Request plumbing

  private struct ContentBody: Encodable {
    let content: String
  }

  /// Mirrors the backend's JSON error body (`{ error, message?, limit? }` — see `api/src/memos/routes.ts`).
  private struct ErrorBody: Decodable {
    let error: String
    let message: String?
    let limit: Int?
  }

  private func request<Body: Encodable>(
    path: String,
    method: String,
    body: Body?
  ) async -> Result<Data, MemoAPIError> {
    let token: String
    do {
      token = try await idTokenProvider()
    } catch {
      return .failure(.unauthorized)
    }

    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
    urlRequest.httpMethod = method
    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    if let body {
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      urlRequest.httpBody = try? JSONEncoder().encode(body)
    }

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: urlRequest)
    } catch {
      return .failure(.network(error))
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      return .failure(.network(URLError(.badServerResponse)))
    }

    switch httpResponse.statusCode {
    case 200, 201, 204:
      return .success(data)
    case 400:
      let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.message ?? "invalid content"
      return .failure(.validation(message: message))
    case 401:
      return .failure(.unauthorized)
    case 403:
      let errorBody = try? JSONDecoder().decode(ErrorBody.self, from: data)
      if errorBody?.error == "limit_reached" {
        return .failure(.limitReached(limit: errorBody?.limit ?? 0))
      }
      return .failure(.forbidden)
    case 404:
      return .failure(.notFound)
    default:
      return .failure(.server(statusCode: httpResponse.statusCode))
    }
  }

  private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> Result<T, MemoAPIError> {
    do {
      return .success(try Memo.jsonDecoder.decode(T.self, from: data))
    } catch {
      return .failure(.decoding(error))
    }
  }
}

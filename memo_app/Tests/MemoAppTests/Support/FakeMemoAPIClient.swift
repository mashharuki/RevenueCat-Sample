import Foundation
@testable import MemoApp

/// In-memory `MemoAPIClienting` test double. `createResults` is queued (one entry consumed per
/// call, sticking on the last entry once exhausted) so a test can simulate an initial
/// `.limitReached` failure followed by a successful retry after the entitlement unlocks.
final class FakeMemoAPIClient: MemoAPIClienting {
  var listResult: Result<[Memo], MemoAPIError> = .success([])
  var createResults: [Result<Memo, MemoAPIError>] = []
  var updateResult: Result<Memo, MemoAPIError> = .failure(.notFound)
  var deleteResult: Result<Void, MemoAPIError> = .success(())

  private(set) var createCallCount = 0

  func listMemos() async -> Result<[Memo], MemoAPIError> {
    listResult
  }

  func createMemo(content: String) async -> Result<Memo, MemoAPIError> {
    defer { createCallCount += 1 }
    guard !createResults.isEmpty else {
      return .failure(.network(URLError(.unknown)))
    }
    let index = min(createCallCount, createResults.count - 1)
    return createResults[index]
  }

  func updateMemo(id: String, content: String) async -> Result<Memo, MemoAPIError> {
    updateResult
  }

  func deleteMemo(id: String) async -> Result<Void, MemoAPIError> {
    deleteResult
  }
}

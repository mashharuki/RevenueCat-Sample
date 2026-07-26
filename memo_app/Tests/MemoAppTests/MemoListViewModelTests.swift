import Foundation
import XCTest
@testable import MemoApp

@MainActor
final class MemoListViewModelTests: XCTestCase {
  func testLoadMemosPopulatesListOnSuccess() async {
    let memo = makeMemo(id: "1", content: "hello")
    let client = FakeMemoAPIClient()
    client.listResult = .success([memo])
    let viewModel = MemoListViewModel(apiClient: client)

    await viewModel.loadMemos()

    XCTAssertEqual(viewModel.memos, [memo])
    XCTAssertNil(viewModel.errorMessage)
  }

  func testLoadMemosSetsErrorMessageOnNetworkFailure() async {
    let client = FakeMemoAPIClient()
    client.listResult = .failure(.network(URLError(.notConnectedToInternet)))
    let viewModel = MemoListViewModel(apiClient: client)

    await viewModel.loadMemos()

    XCTAssertEqual(viewModel.memos, [])
    XCTAssertEqual(viewModel.errorMessage, "ネットワークに接続できないため保存できませんでした。")
  }

  func testCreateMemoInsertsAtFrontOnSuccess() async {
    let existing = makeMemo(id: "existing", content: "old")
    let created = makeMemo(id: "new", content: "new memo")
    let client = FakeMemoAPIClient()
    client.listResult = .success([existing])
    let viewModel = MemoListViewModel(apiClient: client)
    await viewModel.loadMemos()
    client.createResults = [.success(created)]

    await viewModel.createMemo(content: "new memo")

    XCTAssertEqual(viewModel.memos, [created, existing])
    XCTAssertFalse(viewModel.isLimitReached)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testCreateMemoSetsLimitReachedWithoutInsertingOnLimitReachedFailure() async {
    let client = FakeMemoAPIClient()
    client.createResults = [.failure(.limitReached(limit: 20))]
    let viewModel = MemoListViewModel(apiClient: client)

    await viewModel.createMemo(content: "blocked memo")

    XCTAssertEqual(viewModel.memos, [])
    XCTAssertTrue(viewModel.isLimitReached)
  }

  func testRetryPendingMemoCreationSucceedsAfterEntitlementUnlocksAndClearsLimitReached() async {
    let created = makeMemo(id: "retried", content: "blocked memo")
    let client = FakeMemoAPIClient()
    client.createResults = [.failure(.limitReached(limit: 20)), .success(created)]
    let viewModel = MemoListViewModel(apiClient: client)
    await viewModel.createMemo(content: "blocked memo")
    XCTAssertTrue(viewModel.isLimitReached)

    await viewModel.retryPendingMemoCreation()

    XCTAssertEqual(viewModel.memos, [created])
    XCTAssertFalse(viewModel.isLimitReached)
  }

  func testRetryPendingMemoCreationIsNoOpWithoutAPriorLimitReachedFailure() async {
    let client = FakeMemoAPIClient()
    client.createResults = [.success(makeMemo(id: "unexpected", content: "should not be called"))]
    let viewModel = MemoListViewModel(apiClient: client)

    await viewModel.retryPendingMemoCreation()

    XCTAssertEqual(client.createCallCount, 0)
    XCTAssertEqual(viewModel.memos, [])
  }

  func testDismissLimitReachedPromptClearsFlagWithoutRetrying() async {
    let client = FakeMemoAPIClient()
    client.createResults = [.failure(.limitReached(limit: 20))]
    let viewModel = MemoListViewModel(apiClient: client)
    await viewModel.createMemo(content: "blocked memo")
    XCTAssertTrue(viewModel.isLimitReached)

    viewModel.dismissLimitReachedPrompt()

    XCTAssertFalse(viewModel.isLimitReached)
  }

  func testUpdateMemoReplacesAndMovesToFrontOnSuccess() async {
    let original = makeMemo(id: "1", content: "before")
    let other = makeMemo(id: "2", content: "unrelated")
    let updated = makeMemo(id: "1", content: "after")
    let client = FakeMemoAPIClient()
    client.listResult = .success([other, original])
    let viewModel = MemoListViewModel(apiClient: client)
    await viewModel.loadMemos()
    client.updateResult = .success(updated)

    await viewModel.updateMemo(id: "1", content: "after")

    XCTAssertEqual(viewModel.memos, [updated, other])
    XCTAssertNil(viewModel.errorMessage)
  }

  func testDeleteMemoRemovesFromListOnSuccess() async {
    let toDelete = makeMemo(id: "1", content: "bye")
    let other = makeMemo(id: "2", content: "stays")
    let client = FakeMemoAPIClient()
    client.listResult = .success([toDelete, other])
    let viewModel = MemoListViewModel(apiClient: client)
    await viewModel.loadMemos()
    client.deleteResult = .success(())

    await viewModel.deleteMemo(id: "1")

    XCTAssertEqual(viewModel.memos, [other])
  }
}

private func makeMemo(id: String, content: String) -> Memo {
  Memo(id: id, content: content, createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0))
}

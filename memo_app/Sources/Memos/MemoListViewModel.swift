import Foundation

/// Orchestrates memo list retrieval, creation, editing, and deletion against `MemoAPIClienting`,
/// exposing the free-tier limit-reached state so a view can trigger the paywall (Requirement 3.2).
@MainActor
final class MemoListViewModel: ObservableObject {
  @Published private(set) var memos: [Memo] = []
  @Published private(set) var isLimitReached = false
  @Published var errorMessage: String?

  private let apiClient: MemoAPIClienting

  init(apiClient: MemoAPIClienting = MemoAPIClient()) {
    self.apiClient = apiClient
  }

  func loadMemos() async {
    switch await apiClient.listMemos() {
    case .success(let memos):
      self.memos = memos
      errorMessage = nil
    case .failure(let error):
      handle(error)
    }
  }

  func createMemo(content: String) async {
    switch await apiClient.createMemo(content: content) {
    case .success(let memo):
      upsert(memo)
      isLimitReached = false
      errorMessage = nil
    case .failure(let error):
      handle(error)
    }
  }

  func updateMemo(id: String, content: String) async {
    switch await apiClient.updateMemo(id: id, content: content) {
    case .success(let memo):
      upsert(memo)
      errorMessage = nil
    case .failure(let error):
      handle(error)
    }
  }

  func deleteMemo(id: String) async {
    switch await apiClient.deleteMemo(id: id) {
    case .success:
      memos.removeAll { $0.id == id }
      errorMessage = nil
    case .failure(let error):
      handle(error)
    }
  }

  /// Replaces the memo if already present and moves it to the front, keeping the list in
  /// most-recently-updated-first order without a full refetch (Requirement 2.2).
  private func upsert(_ memo: Memo) {
    memos.removeAll { $0.id == memo.id }
    memos.insert(memo, at: 0)
  }

  private func handle(_ error: MemoAPIError) {
    switch error {
    case .limitReached:
      isLimitReached = true
    case .validation(let message):
      errorMessage = message
    case .network:
      errorMessage = "ネットワークに接続できないため保存できませんでした。"
    case .unauthorized, .forbidden, .notFound, .server, .decoding:
      errorMessage = "処理に失敗しました。もう一度お試しください。"
    }
  }
}

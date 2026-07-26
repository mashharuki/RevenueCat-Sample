import SwiftUI

/// Presentational only — lists memos most-recently-updated-first (order is already maintained by
/// `MemoListViewModel`) and lets a user create, edit, or delete memos (Requirements 2.1-2.4).
@MainActor
struct MemoListView: View {
  @StateObject private var viewModel: MemoListViewModel
  @State private var editingMemo: MemoEditTarget?

  init(viewModel: MemoListViewModel? = nil) {
    _viewModel = StateObject(wrappedValue: viewModel ?? MemoListViewModel())
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(viewModel.memos) { memo in
          Button {
            editingMemo = .edit(memo)
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(memo.content)
                .lineLimit(2)
                .foregroundStyle(.primary)
              Text(memo.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
        .onDelete(perform: delete)
      }
      .navigationTitle("メモ")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            editingMemo = .create
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .task {
        await viewModel.loadMemos()
      }
      .alert("エラー", isPresented: errorAlertBinding) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .sheet(item: $editingMemo) { target in
        MemoEditView(viewModel: viewModel, memo: target.memo)
      }
    }
  }

  private var errorAlertBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
    )
  }

  private func delete(at offsets: IndexSet) {
    let idsToDelete = offsets.map { viewModel.memos[$0].id }
    Task {
      for id in idsToDelete {
        await viewModel.deleteMemo(id: id)
      }
    }
  }
}

/// Distinguishes creating a new memo from editing an existing one for the edit sheet.
private enum MemoEditTarget: Identifiable {
  case create
  case edit(Memo)

  var id: String {
    switch self {
    case .create: return "create"
    case .edit(let memo): return memo.id
    }
  }

  var memo: Memo? {
    switch self {
    case .create: return nil
    case .edit(let memo): return memo
    }
  }
}

#Preview {
  MemoListView()
}

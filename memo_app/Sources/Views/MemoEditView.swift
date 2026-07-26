import SwiftUI

/// Presentational only — a single input screen used both to create a new memo and to edit an
/// existing one, saving through the shared `MemoListViewModel` (Requirements 2.1, 2.3).
struct MemoEditView: View {
  @ObservedObject var viewModel: MemoListViewModel
  let memo: Memo?

  @Environment(\.dismiss) private var dismiss
  @State private var content: String
  @State private var isSaving = false

  init(viewModel: MemoListViewModel, memo: Memo?) {
    self.viewModel = viewModel
    self.memo = memo
    _content = State(initialValue: memo?.content ?? "")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextEditor(text: $content)
            .frame(minHeight: 200)
        }

        if let errorMessage = viewModel.errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle(memo == nil ? "新規メモ" : "メモを編集")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("キャンセル") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("保存", action: save)
            .disabled(isSaving || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }

  private func save() {
    isSaving = true
    Task {
      if let memo {
        await viewModel.updateMemo(id: memo.id, content: content)
        isSaving = false
        if viewModel.errorMessage == nil {
          dismiss()
        }
      } else {
        await viewModel.createMemo(content: content)
        isSaving = false
        // `isLimitReached` is only ever set by a create call and cleared by that same call's
        // success, so checking it right after this call is accurate regardless of unrelated
        // prior state (see tasks.md Implementation Notes 5.2).
        if viewModel.errorMessage == nil && !viewModel.isLimitReached {
          dismiss()
        }
      }
    }
  }
}

#Preview {
  MemoEditView(viewModel: MemoListViewModel(), memo: nil)
}

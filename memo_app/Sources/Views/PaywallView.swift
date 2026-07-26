import RevenueCat
import SwiftUI

/// Presentational only — displays the available subscription plan(s) with price/description and
/// wires purchase/restore buttons to `PurchaseService` (Requirements 4.1-4.4). Any terminal
/// purchase/restore outcome (success, cancellation, or failure) dismisses this screen without
/// itself touching entitlement state — that is RevenueCat's/`PurchaseService`'s responsibility.
struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var packages: [Package] = []
  @State private var isLoadingPackages = true
  @State private var isProcessing = false

  var body: some View {
    NavigationStack {
      List {
        if isLoadingPackages {
          ProgressView()
        } else if packages.isEmpty {
          Text("現在利用可能なプランがありません。")
            .foregroundStyle(.secondary)
        } else {
          ForEach(packages) { package in
            Button {
              purchase(package)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(package.storeProduct.localizedTitle)
                  .font(.headline)
                  .foregroundStyle(.primary)
                Text(package.storeProduct.localizedDescription)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                Text(package.localizedPriceString)
                  .font(.title3.bold())
                  .foregroundStyle(.primary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
          }
        }

        Section {
          Button("購入を復元", action: restore)
            .disabled(isProcessing)
        }
      }
      .navigationTitle("アップグレード")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("閉じる") { dismiss() }
        }
      }
      .overlay {
        if isProcessing {
          ProgressView()
        }
      }
      .task {
        packages = await PurchaseService.fetchCurrentPackages()
        isLoadingPackages = false
      }
    }
  }

  private func purchase(_ package: Package) {
    isProcessing = true
    Task {
      _ = await PurchaseService.purchase(package)
      isProcessing = false
      dismiss()
    }
  }

  private func restore() {
    isProcessing = true
    Task {
      _ = await PurchaseService.restore()
      isProcessing = false
      dismiss()
    }
  }
}

#Preview {
  PaywallView()
}

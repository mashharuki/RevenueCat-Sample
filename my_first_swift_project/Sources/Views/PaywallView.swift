import RevenueCat
import SwiftUI

struct PaywallView: View {
  @ObservedObject var viewModel: GameViewModel
  @State private var packages: [Package] = []
  @State private var isLoading = true
  @State private var purchasingIdentifier: String?
  @State private var statusMessage: String?

  var body: some View {
    VStack(spacing: 20) {
      Text("UPGRADE")
        .font(.largeTitle.bold())
        .foregroundColor(.cyan)

      if let banner = viewModel.paywallBanner {
        Text(banner)
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }

      if isLoading {
        Spacer()
        ProgressView().tint(.white)
        Spacer()
      } else if packages.isEmpty {
        Spacer()
        Text("商品を取得できませんでした。\nRevenueCatダッシュボードの設定を確認してください。")
          .foregroundColor(.white.opacity(0.6))
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        Spacer()
      } else {
        ScrollView {
          VStack(spacing: 14) {
            ForEach(packages, id: \.identifier) { package in
              PackageRow(
                package: package,
                isPurchasing: purchasingIdentifier == package.identifier,
                onBuy: { buy(package) }
              )
            }
          }
          .padding(.horizontal)
        }
        Spacer(minLength: 0)
      }

      if let statusMessage {
        Text(statusMessage)
          .font(.footnote)
          .foregroundColor(.orange)
      }

      Button("購入を復元") { Task { await restore() } }
        .font(.footnote)
        .foregroundColor(.white.opacity(0.6))

      Button(action: viewModel.closePaywall) {
        Text("閉じる")
          .font(.title3.bold())
          .padding()
          .frame(maxWidth: .infinity)
      }
      .overlay(Capsule().stroke(Color.cyan))
      .foregroundColor(.cyan)
      .padding(.horizontal)
    }
    .padding(.top, 40)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.ignoresSafeArea())
    .task { await loadPackages() }
  }

  private func loadPackages() async {
    packages = await PurchaseService.fetchCurrentPackages()
    isLoading = false
  }

  private func buy(_ package: Package) {
    purchasingIdentifier = package.identifier
    statusMessage = nil
    Task {
      let outcome = await PurchaseService.purchase(package)
      if case .purchased = outcome, package.identifier == RevenueCatPackages.continueToken {
        viewModel.grantContinueToken()
      }
      purchasingIdentifier = nil
      switch outcome {
      case .purchased:
        statusMessage = "購入が完了しました"
      case .cancelled:
        statusMessage = nil
      case let .failed(error):
        statusMessage = "購入に失敗しました: \(error.localizedDescription)"
      }
    }
  }

  private func restore() async {
    statusMessage = nil
    switch await PurchaseService.restore() {
    case .success:
      statusMessage = "購入情報を復元しました"
    case .failure:
      statusMessage = "復元できる購入が見つかりませんでした"
    }
  }
}

private struct PackageRow: View {
  let package: Package
  let isPurchasing: Bool
  let onBuy: () -> Void

  private var subtitle: String {
    switch package.identifier {
    case RevenueCatPackages.unlockAll:
      "全レベルを無制限にプレイ(買い切り)"
    case RevenueCatPackages.continueToken:
      "ゲームオーバー時に1回だけコンティニュー(消費型)"
    case RevenueCatPackages.weeklyChallenge:
      "週替わりチャレンジモードを解放(週額)"
    default:
      ""
    }
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        Text(package.storeProduct.localizedTitle)
          .font(.headline)
          .foregroundColor(.white)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
      }
      Spacer()
      Button(action: onBuy) {
        Group {
          if isPurchasing {
            ProgressView().tint(.black)
          } else {
            Text(package.storeProduct.localizedPriceString)
          }
        }
        .frame(width: 90)
        .padding(.vertical, 10)
      }
      .disabled(isPurchasing)
      .background(Color.cyan)
      .foregroundColor(.black)
      .clipShape(Capsule())
    }
    .padding(16)
    .background(Color.white.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3)))
  }
}

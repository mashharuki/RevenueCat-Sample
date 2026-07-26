import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:my_first_game/services/purchase_service.dart';
import 'package:my_first_game/state/game_session.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

class PaywallScreen extends StatefulWidget {
  final GameSession session;

  const PaywallScreen({super.key, required this.session});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Future<List<Package>> _packagesFuture;
  String? _purchasingIdentifier;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _packagesFuture = fetchCurrentPackages();
  }

  Future<void> _buy(Package package) async {
    setState(() {
      _purchasingIdentifier = package.identifier;
      _statusMessage = null;
    });

    final outcome = await purchase(package);

    if (outcome is Purchased &&
        package.identifier == RevenueCatPackages.continueToken) {
      widget.session.grantContinueToken();
    }

    if (!mounted) return;
    setState(() {
      _purchasingIdentifier = null;
      _statusMessage = switch (outcome) {
        Purchased() => '購入が完了しました',
        Cancelled() => null,
        PurchaseFailed(:final error) => '購入に失敗しました: $error',
      };
    });
  }

  Future<void> _restore() async {
    setState(() => _statusMessage = null);
    final info = await restorePurchases();
    if (!mounted) return;
    setState(() {
      _statusMessage = info != null ? '購入情報を復元しました' : '復元できる購入が見つかりませんでした';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'UPGRADE',
                style: AppTheme.orbitron(fontSize: 30, color: AppTheme.cyan),
              ),
              if (widget.session.paywallBanner != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.session.paywallBanner!,
                  textAlign: TextAlign.center,
                  style: AppTheme.rajdhani(fontSize: 14, color: Colors.white70),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<List<Package>>(
                  future: _packagesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final packages = snapshot.data!;
                    if (packages.isEmpty) {
                      return Center(
                        child: Text(
                          '商品を取得できませんでした。\nRevenueCatダッシュボードの設定を確認してください。',
                          textAlign: TextAlign.center,
                          style: AppTheme.rajdhani(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: packages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _PackageCard(
                        package: packages[index],
                        isPurchasing:
                            _purchasingIdentifier == packages[index].identifier,
                        onBuy: () => _buy(packages[index]),
                      ),
                    );
                  },
                ),
              ),
              if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: AppTheme.rajdhani(
                    fontSize: 12,
                    color: AppTheme.orange,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: _restore,
                child: Text(
                  '購入を復元',
                  style: AppTheme.rajdhani(fontSize: 13, color: Colors.white54),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: NeonButton(
                  label: '閉じる',
                  onPressed: widget.session.closePaywall,
                  primary: false,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final bool isPurchasing;
  final VoidCallback onBuy;

  const _PackageCard({
    required this.package,
    required this.isPurchasing,
    required this.onBuy,
  });

  String get _subtitle => switch (package.identifier) {
    RevenueCatPackages.unlockAll => '全ウェーブを無制限にプレイ(買い切り)',
    RevenueCatPackages.continueToken => 'ゲームオーバー時に1回だけコンティニュー(消費型)',
    RevenueCatPackages.weeklyChallenge => '週替わりチャレンジモードを解放(週額)',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xD90E1224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.storeProduct.title,
                  style: AppTheme.orbitron(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle,
                  style: AppTheme.rajdhani(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: isPurchasing ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isPurchasing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.background,
                      ),
                    )
                  : Text(
                      package.storeProduct.priceString,
                      style: AppTheme.rajdhani(fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

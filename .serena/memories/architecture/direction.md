# 技術方針

- 2026-08-01: ユーザーは検討の結果、フルスタック構成として React Native + Cloudflare を有力な方針として選択した。
- 次の設計・実装では、モバイルは React Native（Expo を含め検討）、バックエンドは Cloudflare のエッジ基盤を前提にする。ただし具体的なサービス選定（Workers/D1/R2/KV/Queues 等）は要件に応じて決める。

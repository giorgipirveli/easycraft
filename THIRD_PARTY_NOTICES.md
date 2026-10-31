# Third-party code

Code by others that EasyCraft ships in the game or uses to build its server. Art, sound and other
assets are credited in `assets/CREDITS.md` (all CC0). Keep this list current when a library is
added; before the store release (M5) the game's About/Licences screen must show these notices.

## Shipped in the game

| Library | Where | Licence | Notes |
|---|---|---|---|
| Godot Engine 4.7.2 | the engine | MIT | https://godotengine.org/license |
| Voxel Tools 1.7 (Marc Gilleron) | `addons/zylann.voxel/` | MIT, `addons/zylann.voxel/LICENSE.md` | GDExtension binaries |
| Nakama client for Godot 4 (Heroic Labs, nakama-godot) | `addons/com.heroiclabs.nakama/` | Apache License 2.0, `addons/com.heroiclabs.nakama/LICENSE` | Unmodified; pinned commit and what was left out: `addons/com.heroiclabs.nakama/SOURCE.md` (M4 online play) |
| godot-mcp game bridge (satelliteoflove) | `addons/godot_mcp/` | MIT | Developer tool; M5 decides whether release builds leave it out |

## Planned for the game (not bundled yet)

| Library | Where it will go | Licence | Notes |
|---|---|---|---|
| Godot Google Play Billing plugin 3.3.0 (Godot Engine contributors, github.com/godot-sdk-integrations/godot-google-play-billing) | `addons/GodotGooglePlayBilling/` (AAR + export plugin), only when the owner turns the shop on | MIT (Copyright (c) 2020 Godot Engine contributors) | Owner #35: the Google Play backend of the shop (`core/shop/play_billing.gd` talks to its `GodotGooglePlayBilling` singleton). Adds Google's Play Billing Library (`com.android.billingclient:billing-ktx:9.1.0`, Android Software Development Kit License / Google Play terms) to Gradle builds. Needs the Gradle build; steps in `docs/devlog/parts/owner-35-shop.md` |

## Development only (not in the game)

| Library | Where | Licence |
|---|---|---|
| GUT 9.7.1 (Godot Unit Test) | `addons/gut/` (excluded from exports) | MIT, `addons/gut/LICENSE.md` |
| Nakama runtime type definitions (Heroic Labs, nakama-common 1.48.0) | `server/modules/vendor/nakama-runtime/` | Apache License 2.0, `LICENSE` there; `index.d.ts` unmodified |
| TypeScript 5.9.3 | `server/modules` (npm) | Apache License 2.0 |

## Server software (run as Docker images, not redistributed)

| Software | Image | Licence |
|---|---|---|
| Nakama 3.41.0 (Heroic Labs) | `heroiclabs/nakama:3.41.0` | Apache License 2.0 |
| PostgreSQL 16.8 | `postgres:16.8-alpine` | PostgreSQL License |
| PostgreSQL 16 (latest 16.x; the hosting kit's database and backup tools) | `postgres:16-alpine` | PostgreSQL License |
| Caddy 2.11 (HTTPS in front of Nakama on the owner's server, `server/deploy/`) | `caddy:2.11-alpine` | Apache License 2.0 |
| Node.js 24 (builds the server module inside the hosting kit's image; runs `./kit.sh check`; not in the server image) | `node:24-alpine` | MIT |

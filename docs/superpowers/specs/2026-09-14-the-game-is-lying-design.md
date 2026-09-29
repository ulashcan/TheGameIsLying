# THE GAME IS LYING — MVP Design

Date: 2026-09-14

## Intent
A portrait iOS puzzle that makes the player distrust on-screen instructions. Each level is 5–15 seconds, one idea, instantly readable in a TikTok cut.

## Scope lock
Two user specs conflicted (30 levels vs 10-level MVP). **MVP ships 10 unique levels.** Catalog is data-driven so 11–30 can be added without engine work.

Out of scope: backend, accounts, multiplayer, inventory, SpriteKit, live AdMob SDK, paywall UI.

## Approaches
1. **SwiftUI + Canvas (chosen)** — Buttons, type, timers. Fastest path to a playable ad-test build.
2. SpriteKit overlay — Extra scene/camera cost for no gameplay gain.
3. UIKit — More boilerplate, same result.

**Decision:** Native Swift / SwiftUI, iOS 17+, iPhone portrait, fully offline.

## Architecture
- `Level` data + `WinRule` enum. New levels = catalog rows.
- `GameEngine` is pure: `(action, level, state, elapsed) -> outcome`. Unit-tested.
- `GameSession` (`@Observable`, `@MainActor`) owns navigation and persistence.
- Trust is hidden: `trustedCount` / `ignoredCount` / `lastColorID` change later levels, never shown as a score.
- Ads / analytics / premium are protocols. Default ads **off**. Rewarded flow still grants hint/continue so QA works offline.

## Screens
1. Home — title, PLAY, “Can you trust it?”, tiny daily entry.
2. Gameplay — LEVEL, instruction, one interaction, hint.
3. Fail — GAME OVER + level fail copy + TRY AGAIN + WATCH AD → CONTINUE.
4. Success — YOU GOT ME / NICE + NEXT (auto-advance ~0.8s).

## 10 levels
1. Don’t press red — true; wait wins.
2. Press red — lie; wait wins.
3. Don’t touch the screen — wait; any tap loses.
4. Press blue — red wins.
5. Safe / Death doors — depends on last color.
6. “You pressed RED before” — yes/no vs real history.
7. Three labeled buttons — only tapping the LEVEL label wins.
8. Press the same color as last time — opposite color wins.
9. Press NOW — early tap loses, tap after delay wins.
10. “You still trust me?” — trusted majority must tap NO; skeptics must tap YES.

## Feedback
Fast scale / shake / flash. Programmatic WAV + system-sound fallback. Sensory haptics.

## Monetization / retention stubs
- `AdManager` + Google test IDs as constants, no production IDs, no SDK required.
- Analytics protocol: session/level/retry/hint/rewarded events.
- Daily challenge: date ordinal → level id.
- `PremiumFlags` for later remove-ads / themes / packs.

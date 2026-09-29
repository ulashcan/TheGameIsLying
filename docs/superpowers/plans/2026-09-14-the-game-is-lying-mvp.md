# THE GAME IS LYING MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a playable iPhone portrait SwiftUI puzzle MVP with 10 unique lying-instruction levels.

**Architecture:** Pure `GameEngine` + data-driven `LevelCatalog` + `@Observable` `GameSession`. SwiftUI screens. Ads/analytics/premium as local abstractions.

**Tech Stack:** Swift 5, SwiftUI, iOS 17+, XCTest, AVFoundation, no backend.

## Global Constraints
- iOS 17+, iPhone, portrait only
- Offline; ads default off
- No production AdMob IDs
- 10 unique levels in `LevelCatalog`
- Hidden trust state, never shown as a number
- User asked to implement in this session (inline execution)

---

### Task 1: Xcode project + failing engine tests

**Files:**
- Create: `TheGameIsLying.xcodeproj/project.pbxproj`
- Create: `TheGameIsLying/Game/Models/GameModels.swift`
- Create: `TheGameIsLying/Game/Core/GameEngine.swift` (stub)
- Create: `TheGameIsLyingTests/GameEngineTests.swift`

- [ ] **Step 1: Write failing tests** for level 1 press-red lose / wait win
- [ ] **Step 2: Run** `xcodebuild test -scheme TheGameIsLying -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'`
- Expected: FAIL (stub returns `stillPlaying`)
- [ ] **Step 3: Implement GameEngine + catalog**
- [ ] **Step 4: Re-run tests** — PASS
- [ ] **Step 5: Commit** — skipped (user did not ask)

### Task 2: 10-level catalog + state/retry tests

**Files:**
- Create: `TheGameIsLying/Game/Levels/LevelCatalog.swift`
- Create: `TheGameIsLyingTests/LevelCatalogTests.swift`
- Create: `TheGameIsLyingTests/PlayerStateTests.swift`

### Task 3: Session + persistence + UI

**Files:**
- Create: `GameSession.swift`, `HomeView.swift`, `GameplayView.swift`, `ResultView.swift`, `TheGameIsLyingApp.swift`

### Task 4: Audio, haptics, ads, analytics, daily, premium stubs

**Files:**
- Create: `AudioService.swift`, `AdManager.swift`, `AnalyticsClient.swift`, `DailyChallengeService.swift`, `PremiumFlags.swift`

### Task 5: Build + verify

Run:
- `xcodebuild test`
- `xcodebuild build`
- Confirm 10 levels, retry, ads-off, offline

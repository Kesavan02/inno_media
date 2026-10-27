# PRODUCT.md — Durable Product Truth

## 1. Product Summary & Purpose
**InnoMedia** is a production-grade mobile application designed to showcase two core engineering competencies:
1. **Social Media Experience**: An immersive social feed (stories tray, rich post cards with likes, bookmarks, and comments) and a high-performance, **offline Reels feature utilizing 5 local video files** with auto-play and persistence.
2. **JSON-Driven Dynamic Form Engine**: A resilient, non-hardcoded form system that interprets runtime JSON configurations to generate complex forms supporting 19 field types, dynamic conditional visibility (`visibleIf`), and dependent dropdowns (`dependsOn` + `optionsMap`).

---

## 2. Target Audience & Operating Context
- **Primary Audience**: Technical assessment evaluators, hiring committees, and senior mobile architects evaluating clean code, state management, design decisions, and system thinking.
- **Operating Context**: Android & iOS mobile environments. Offline-first resilience: local video files and local persistent stores (`SharedPreferences`) ensure zero network dependency for core features.

---

## 3. Core Technical Constraints

| Constraint | Architectural Decision | Implementation Rationale |
| :--- | :--- | :--- |
| **State Management** | BLoC (`flutter_bloc 9`) | Clear separation of UI events, business logic emissions, and predictable immutable states. |
| **Architecture** | Clean Architecture | Strict layer boundaries: `Presentation` ➔ `Domain` ➔ `Data`. Business rules have zero dependencies on frameworks or UI. |
| **Data Flow Indexing** | $O(1)$ Indexed Stores | In-memory `IndexedCollection<K, V>` and `PaginationCursor` prevent $O(N)$ overhead; `FormConfigEntity.fieldIndex` resolves schema dependencies in $O(1)$ time. |
| **Data Flow Rate Limiting** | Sliding-Window Token Limiter | `RateLimiter` enforces frequency caps on likes (max 6 / 4s) and form submissions (max 1 / 3s) to prevent spamming and duplicate submissions. |
| **Security** | Salted SHA-256 Hashing | Passwords are **never stored in plain text**. Unique cryptographic salt per user ensures credential safety. |
| **Offline Media** | 5 Local MP4 Assets | Reels work 100% offline without network buffering or external link breakage. |

---

## 4. Key User Journeys

1. **Authentication Journey**:
   - User registers or logs in with 10-digit mobile number and password.
   - Credentials hashed with salt; session stored locally.
   - Evaluator can tap "Auto Fill" demo credentials (`9876543210` / `Password@123`) for instant access.
2. **Social Home Feed Journey**:
   - Browse Stories carousel with multi-stop conic gradient indicators; tap to enter full-screen viewer with animated 5-second progress bars.
   - Scroll posts with infinite pagination; double-tap photo to trigger heart burst animation.
   - Open comments bottom sheet to inspect or add comments with instant local persistence.
3. **Reels Experience Journey**:
   - Vertical swipe through 5 local video reels. Active reel auto-plays; previous reel pauses immediately.
   - Single-tap toggles play/pause with visual indicator; double-tap likes with heart burst.
   - Interactive likes, comments sheet, share counter, and rotating vinyl disc.
4. **Dynamic JSON Form Engine Journey**:
   - Render 19 field types interpreted from JSON configuration at runtime.
   - Toggle `Married` switch ➔ `spouse_name` conditionally discloses with smooth animation.
   - Select `Country` (India / USA / Canada) ➔ `State` dropdown dynamically populates corresponding states.
   - Real-time validation alerts for invalid inputs; rate-limited submission saves data and routes to verified summary card.
   - Open **"JSON Schema"** live editor ➔ paste any custom JSON schema on the fly and watch the form rebuild in real time.

---

## 5. Cloud Firestore Structural Schema

| Collection | Document ID Pattern | Document Fields & Schema | Purpose |
|:---|:---|:---|:---|
| **`form_submissions`** | `sub_{timestamp}` | `id`, `formTitle`, `values: Map<String, dynamic>`, `submittedAt: ISO8601`, `syncedAt: serverTimestamp()` | Structured records of all dynamic form submissions. |
| **`form_schemas`** | `{schemaId}` (e.g. `default`) | `id`, `title`, `rawJson: String`, `updatedAt: serverTimestamp()` | Remote runtime storage and distribution of JSON form definitions. |
| **`users`** | `{mobile}` | `id`, `mobile`, `fullName`, `email`, `passwordHash`, `salt`, `bio`, `avatarUrl`, `updatedAt: serverTimestamp()` | Synchronized user profile documents with salted credentials. |
| **`posts`** | `post_{id}` | `id`, `userId`, `userName`, `userAvatar`, `caption`, `mediaUrl`, `likesCount`, `likedUserIds: Array`, `commentsCount`, `updatedAt` | Social feed posts with real-time like/comment tallies. |
| **`posts/{postId}/comments`** | `cmt_{timestamp}` | `id`, `authorName`, `authorAvatar`, `text`, `createdAt`, `createdAtTimestamp: serverTimestamp()` | Hierarchical subcollection for nested, scalable comment threads. |

---

## 6. Verification & Quality Gates
- **Zero Analysis Issues**: `flutter analyze` must pass with 0 errors and 0 warnings.
- **Unit & Logic Tests**: Full test suite verifying password hashing, rate limiting, and conditional schema evaluation.
- **Deterministic Automation**: All interactive elements possess explicit `Key` identifiers for automated test runs.

# InnoMedia — Social Platform & Dynamic JSON Form Engine

An enterprise-grade Flutter application built with **Clean Architecture** and **BLoC (flutter_bloc 9)**, featuring a social media experience (Feed, Stories, 5-Video Offline Reels) and a runtime **JSON-driven dynamic form engine**. 

The UI and art direction strictly follow the **Taste Skill** guidelines ([Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)), eliminating generic AI template tropes in favor of editorial typography, an obsidian/slate color palette, and tactile micro-interactions.

---

## 🏛️ System Design & Clean Architecture

The codebase adheres strictly to Uncle Bob's Clean Architecture principles with clear layer boundaries:

```
lib/
├── core/
│   ├── constants/            # App keys, storage identifiers, rate limit thresholds
│   ├── di/                   # Service Locator via get_it (Dependency Injection)
│   ├── errors/               # Failures & Exceptions mapping
│   ├── indexing/             # O(1) indexed data stores and cursor pagination
│   ├── rate_limiter/         # Sliding-window rate limiter & debouncer
│   ├── theme/                # Taste-skill design tokens, typography, dark theme
│   ├── utils/                # Cryptographic salted password hasher (SHA-256)
│   └── widgets/              # Tactile bounce & frosted glass components
├── features/
│   ├── auth/                 # Authentication, salted registration, session persistence
│   │   ├── data/             # Local data source (SharedPreferences + hashing), DTOs
│   │   ├── domain/           # UserEntity, AuthRepository, Login/Register/Logout use cases
│   │   └── presentation/     # AuthBloc, Login & Register pages
│   ├── feed/                 # Social Feed & Stories
│   │   ├── data/             # Indexed post cache, persistent interactions
│   │   ├── domain/           # Post, Story, Comment entities and interaction use cases
│   │   └── presentation/     # FeedBloc, StoriesTray, StoryViewerDialog, PostCard
│   ├── reels/                # Short Videos Experience (5 local offline videos)
│   │   ├── data/             # Local video asset sources, likes & comment persistence
│   │   ├── domain/           # ReelEntity, interaction use cases
│   │   └── presentation/     # ReelsBloc, ReelVideoPlayerItem, ReelActionSidebar
│   ├── dynamic_form/         # Runtime JSON-driven form engine
│   │   ├── data/             # JSON asset loader, schema parsing, submission store
│   │   ├── domain/           # FormConfigEntity, FormFieldConfigEntity, Validation rules
│   │   └── presentation/     # DynamicFormBloc, FieldRendererFactory, Live JSON Editor
│   └── navigation/           # Main shell with persistent IndexedStack tabs & profile
└── main.dart                 # App entry point, MultiBlocProvider, root routing
```

---

## ⚡ Indexing & Rate Limiting in Data Flow

As explicitly mandated, data flow indexing and rate limits are deeply engineered into the system:

### 1. Data Flow Indexing
* **`IndexedCollection<K, V>`**: An in-memory indexed storage structure with $O(1)$ primary key lookups and cached ordered indexing, eliminating costly $O(N)$ list traversals.
* **`PaginationCursor`**: Manages cursor-based, indexed batch retrieval (`pageIndex`, `pageSize`, `hasMore`, `totalIndexed`) for infinite scroll streams.
* **Dynamic Form Field Indexing**: Form fields are indexed by unique `id` in `FormConfigEntity.fieldIndex`. During conditional evaluation (`visibleIf`) and dependent option lookups (`dependsOn`), dependencies resolve instantaneously in $O(1)$ time.

### 2. Rate Limiting Architecture
* **`RateLimiter`**: A sliding-window token algorithm that tracks action timestamps and enforces frequency limits:
  * **Like Actions**: Throttled to prevent spamming like taps (`maxRequests: 6`, `window: 4s`).
  * **Form Submissions**: Throttled to prevent double-submit payloads (`maxRequests: 1`, `window: 3s`).
  * **Brute-Force Guard**: Authentication attempts throttled to mitigate credential attacks.
  * When a rate limit threshold is breached, the repository produces a domain `RateLimitFailure` which the BLoC maps into non-blocking user feedback while rolling back optimistic UI states.
* **`Debouncer`**: Smooths rapid keystroke inputs and slider events without triggering excessive widget rebuilds.

---

## 🎨 Taste Skill UI/UX Integration (`Leonxlnx/taste-skill`)

The visual design eliminates "AI slop" (muddy purple gradient washes, generic floating action buttons, unstyled inputs):

* **Art Direction & Tone**: Obsidian base (`#090C10`), Slate card surfaces (`#131822`, `#1C2333`), and Electric Coral/Crimson primary accents (`#FF3366`).
* **Tunable Dials**:
  * `DESIGN_VARIANCE = 8`: Multi-stop conic gradient story rings, asymmetrical metadata badges, frosted glass navigation overlays.
  * `MOTION_INTENSITY = 7`: Spring physics button press (`TactileBounce`), double-tap heart expansion and rotation bursts, vinyl audio disc rotation, and animated field disclosures.
  * `VISUAL_DENSITY = 4`: Generous 16–20dp padding, subtle hairline borders (`0.8px` width), zero cluttered elements.
* **Typography Discipline**: High-character **Plus Jakarta Sans** with negative letter-spacing on display headlines and clean body tracking.

---

## 📱 Feature Capabilities

### Task 1: Social Media Experience
1. **User Access**:
   * Registration and Login using mobile number and password.
   * Passwords are **never stored in plain text**: Salted key-stretching with SHA-256 via `PasswordHasher`.
   * Session persistence and quick one-tap Demo Auto-Fill (`9876543210` / `Password@123`).
2. **Home Feed**:
   * **Stories Tray**: Conic gradient ring avatars with tap-to-view.
   * **Full-Screen Story Viewer**: Animated 5-second progress bars, tap-left/right navigation, and caption overlays.
   * **Post Feed**: Author verification badges, double-tap heart burst animation, like counter, bookmarking, and interactive comments sheet.
3. **Reels (Short Videos)**:
   * **5 local video files** bundled in `assets/videos/` (`reel_1.mp4` to `reel_5.mp4`), fully functional offline without network dependency.
   * Vertical `PageView` with automatic play on active reel and pause when swiped away.
   * Tap-to-pause/play toggle, double-tap heart bursts, persistent likes and comment bottom sheets, and spinning vinyl music discs.

### Task 2: Dynamic JSON-Driven Form Engine
1. **Comprehensive Field Support**:
   * Text, Email (Regex), Phone (10 digits), Password (obscure toggle), Textarea.
   * Number, Slider (Years of experience with live value label).
   * Date Picker (Date of birth), Time Picker (Joining time).
   * Radio Group (Gender), Dropdown (Department, Country).
   * Multi-select Checkbox (Skills), Single Checkbox (Terms & conditions acceptance).
   * File Upload Simulator (Resume document selector with PDF/DOC/DOCX validation).
   * Image Upload Simulator (Profile avatar picker with live circle preview).
2. **Conditional Visibility (`visibleIf`)**:
   * `spouse_name` is only rendered and validated if `is_married` is toggled `true`.
   * Hiding a field clears its value and errors automatically.
3. **Dependent Dropdowns (`dependsOn` + `optionsMap`)**:
   * Selecting `Country` (`India`, `USA`, `Canada`) dynamically loads corresponding `State` options.
   * Resetting or changing country automatically cascades and refreshes dependent states.
4. **Live JSON Schema Editor**:
   * A built-in live schema editor (`/json_editor`) allows interviewers to paste or edit ANY custom JSON configuration on the fly and verify that the form rebuilds dynamically at runtime!
5. **Submission Summary Screen**:
   * Form submissions are validated and presented in a verified summary card.

---

## 🧪 Testing & Code Quality

* **Unit Tests**:
  * `PasswordHasher` salted hashing and credential verification tests.
  * `RateLimiter` token bucket and sliding-window boundary tests.
  * `ConditionalRuleEntity` logic and `FormFieldConfigEntity` validation constraint tests.
  * Run with: `flutter test` (100% pass).
* **Static Analysis**:
  * `flutter analyze` reports **0 issues** across all packages and clean architecture layers.

---

## 🚀 Getting Started

### 1. Prerequisites
* Flutter SDK (3.24+ or 3.47+)
* Android SDK / Android Studio (or physical Android device / emulator)

### 2. Run the Application
```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run
```

### 3. Build Release APK
```bash
flutter build apk --release
```
The output APK file will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

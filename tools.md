# 🛠️ Tools & Technologies Used

> A full breakdown of every tool, technology, and AI used to build **Emoji Dodger**.

---

## 🤖 AI Used

### Claude (by Anthropic)
| Detail | Info |
|---|---|
| **Model** | Claude Sonnet 4.6 |
| **Made by** | [Anthropic](https://www.anthropic.com) |
| **Used via** | [claude.ai](https://claude.ai) |
| **Role** | Generated 100% of the game code, pubspec, README, prompt, and this file |

**What Claude did:**
- Designed the full game architecture from a single sentence prompt
- Wrote all Dart/Flutter game logic (collision, timers, state machine)
- Designed the UI/UX (space theme, animations, overlays)
- Generated the `README.md` with badges, tables, and ASCII art
- Wrote the detailed shareable prompt
- Generated this `TOOLS.md`

> 💡 *The entire project was built in a single conversation with Claude — no manual coding required.*

---

## 💻 Programming Language

### Dart
| Detail | Info |
|---|---|
| **Version** | `>=3.0.0 <4.0.0` |
| **Website** | [dart.dev](https://dart.dev) |
| **Role** | Core language for all game logic and UI |

**Dart libraries used:**

| Library | Purpose |
|---|---|
| `dart:math` | `Random` for spawning, `sin()` + `sqrt()` + `pow()` for collision & shake |
| `dart:async` | `Timer` and `Timer.periodic` for game loop and spawning |

---

## 📱 Framework

### Flutter
| Detail | Info |
|---|---|
| **Version** | `>=3.10.0` |
| **Website** | [flutter.dev](https://flutter.dev) |
| **Role** | Cross-platform UI framework — renders the entire game |

**Flutter packages used (all built-in, zero external deps):**

| Package | Purpose |
|---|---|
| `package:flutter/material.dart` | Widgets, theming, layout, gestures |
| `package:flutter/services.dart` | `HapticFeedback`, `SystemChrome` orientation lock |

**Flutter features leveraged:**

| Feature | Used For |
|---|---|
| `StatefulWidget` | Game state management |
| `TickerProviderStateMixin` | Powering `AnimationController` |
| `AnimationController` | Screen shake + pulse animations |
| `Stack` + `Positioned` | Placing player & enemies at exact coordinates |
| `LayoutBuilder` | Reading live screen dimensions |
| `GestureDetector` | Drag and tap input |
| `LinearGradient` | Space background + ground glow |
| `BoxShadow` | Cyan glow under player |
| `Timer.periodic` | 60fps game loop |
| `AnimatedBuilder` | Rebuild only shake widget on animation tick |
| `Transform.translate` | Applying shake offset |
| `Transform.scale` | Pulsing start button |

---

## 🧠 Game Design Concepts

| Concept | Implementation |
|---|---|
| **Game Loop** | `Timer.periodic` at 16ms (~60fps) |
| **Entity System** | `FallingEmoji` data class with `x`, `y`, `speed`, `emoji`, `size` |
| **State Machine** | `GameState` enum: `idle → playing → gameOver` |
| **Normalized Coords** | All positions stored as 0.0–1.0 fractions, scaled by screen size at render time |
| **Circle Collision** | Euclidean distance between player center and enemy center vs sum of radii |
| **Difficulty Curve** | Linear ramp every 5s — spawn interval ↓, speed ↑, clamped at limits |
| **Randomness** | `dart:math Random` for x-position, speed variance (±30%), emoji choice, size |

---

## 🎨 Design Tools

| Tool | Purpose |
|---|---|
| **Emojis (Unicode)** | All visuals — player, enemies, stars, UI icons (no image assets needed) |
| **CSS-style Gradients** | Space background atmosphere via Flutter `LinearGradient` |
| **Mathematical animation** | `sin()` wave for screen shake, `Curves.elasticIn` for timing |

---

## 🗂️ File Structure

```
emoji_dodger/
├── lib/
│   └── main.dart       # 100% AI-generated — full game in one file
├── pubspec.yaml        # AI-generated — zero external dependencies
├── README.md           # AI-generated — full GitHub documentation
├── TOOLS.md            # AI-generated — this file
└── PROMPT.md           # Shareable prompt to recreate the project
```

---

## 📦 Dependencies

```yaml
# External packages: NONE
# Everything uses Flutter's built-in SDK only.

dependencies:
  flutter:
    sdk: flutter
```

> ✅ No `pub.dev` packages. No third-party plugins. No API keys. Just Flutter.

---

## 🧑‍💻 Development Environment (Recommended)

| Tool | Version | Purpose |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.10+ | Run & build the app |
| [Dart SDK](https://dart.dev/get-dart) | 3.0+ | Included with Flutter |
| [Android Studio](https://developer.android.com/studio) | Latest | Android emulator & build |
| [Xcode](https://developer.apple.com/xcode/) | 14+ (macOS only) | iOS build & simulator |
| [VS Code](https://code.visualstudio.com/) + Flutter extension | Latest | Recommended code editor |

---

## 🚀 Platform Support

| Platform | Supported |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ⚠️ (works but not optimized) |
| macOS / Windows / Linux | ⚠️ (desktop input differs) |

---

## 📊 Project Stats

| Metric | Value |
|---|---|
| Lines of code | ~370 |
| External dependencies | 0 |
| Image assets | 0 |
| Time to generate | < 2 minutes |
| AI prompts used | 1 |

---

<p align="center">
  Built entirely with 🤖 <strong>Claude AI</strong> + 💙 <strong>Flutter</strong> — no manual coding required.
</p>
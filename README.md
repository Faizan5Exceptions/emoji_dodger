# 🧑 Emoji Dodger

> A fast-paced Flutter arcade game — dodge the falling chaos or get wrecked!

![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## 🎮 Gameplay

Emojis rain down from the top of the screen. You control a player 🧑 at the bottom — move left and right to survive as long as possible. One hit and it's **Game Over**.

```
💣     ☄️        🪨
    ⚡       🔥
        🌪️

━━━━━━━━━━━━━━━━━━━━━━━
           🧑
```

The longer you survive, the faster and more frequent the emojis become. How long can you last?

---

## ✨ Features

- 🕹️ **Smooth drag & tap controls** — drag anywhere or tap to move instantly
- 📈 **Progressive difficulty** — speed and spawn rate increase every 5 seconds
- 💥 **Screen shake on death** — satisfying elastic shake animation
- ⭐ **Live score** — increments every frame you survive
- 🏆 **High score tracking** — persists across rounds within a session
- 🎉 **New high score celebration** — get rewarded for beating your best
- 📳 **Haptic feedback** on game over (real devices)
- 🌌 **Space-themed dark UI** with animated star field background
- 🚀 **Pulsing start screen** with smooth animations
- Zero dependencies — uses only the Flutter SDK

---

## 📱 Screenshots

| Start Screen | Gameplay | Game Over |
|---|---|---|
| 🚀 Pulsing title with start button | 🧑 Dodge the falling emojis! | 💥 Shake effect + score summary |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.10.0`
- Dart `>=3.0.0`
- Android Studio / Xcode (for device/emulator)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Faizan5Exceptions/emoji_dodger.git
cd emoji-dodger

# 2. Get dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 🕹️ Controls

| Action | Control |
|---|---|
| Move left / right | **Drag** anywhere on screen |
| Jump to position | **Tap** anywhere on screen |

---

## 🗂️ Project Structure

```
emoji_dodger/
├── lib/
│   └── main.dart        # All game logic, UI, and state
├── pubspec.yaml         # Project configuration
└── README.md
```

All game code lives in a single `main.dart` for simplicity:

| Class / Enum | Role |
|---|---|
| `EmojiDodgerApp` | App entry point |
| `GameScreen` | Main stateful widget |
| `FallingEmoji` | Data model for each enemy |
| `GameState` | `idle` / `playing` / `gameOver` |

---

## ⚙️ Game Mechanics

| Parameter | Start Value | Min / Max |
|---|---|---|
| Spawn interval | 1200 ms | 300 ms |
| Enemy base speed | 0.003 (screen/tick) | 0.012 |
| Difficulty ramp | Every 5 seconds | — |
| Hit detection | Circle-circle collision | radius ≈ 45% of size |

---

## 🛠️ Built With

- [Flutter](https://flutter.dev/) — UI framework
- [Dart](https://dart.dev/) — Language
- `dart:math` — Random spawning & collision math
- `dart:async` — Game loop & spawn timers

---

## 🤝 Contributing

Contributions are welcome! Here are some ideas to extend the game:

- [ ] Sound effects & background music
- [ ] Power-ups (shields, slow-motion)
- [ ] Multiple player skins
- [ ] Persistent high score with `shared_preferences`
- [ ] Leaderboard with Firebase
- [ ] Difficulty selection screen

```bash
# Fork → create your branch → commit → open a PR
git checkout -b feature/my-awesome-feature
git commit -m "Add my awesome feature"
git push origin feature/my-awesome-feature
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ and Flutter &nbsp;|&nbsp; Star ⭐ this repo if you had fun!</p>
# 📝 PROMPT.md

> The exact AI prompt used to generate the **Emoji Dodger** Flutter game from scratch.
> Copy this prompt into [Claude.ai](https://claude.ai) and get the full project instantly.

---

## 🎯 Original Prompt (What Started It All)

```
in flutter make a game emoji dogger emoji will fall from top to down 
and our player will be in bottom of screen so when emoji hit the 
player game over
```

> ✅ That's it. One sentence. The entire game was generated from this.

---

## 🚀 Full Detailed Prompt (Recreate Exact Output)

Use this expanded version to regenerate the complete project with all features:

---

```
Create a complete Flutter arcade game called "Emoji Dodger" in a single 
main.dart file with the following specifications:

──────────────────────────────────────────
CORE GAMEPLAY
──────────────────────────────────────────
Build a dodge game where random danger emojis (💣 ☄️ 🪨 ⚡ 🔥 🌪️ 💀 🦠 🧨 🪤) 
fall from the top of the screen to the bottom. The player (🧑) is positioned 
at the bottom of the screen and must dodge the falling emojis. If any emoji 
collides with the player, the game ends immediately.

──────────────────────────────────────────
CONTROLS
──────────────────────────────────────────
- Dragging anywhere on screen moves the player left or right smoothly
- Tapping anywhere on screen instantly jumps the player to that X position

──────────────────────────────────────────
GAME STATES
──────────────────────────────────────────
Implement three states — idle, playing, and gameOver — using an enum 
called GameState.

──────────────────────────────────────────
DIFFICULTY & SCORING
──────────────────────────────────────────
- Score increments every frame (every 16ms game loop tick)
- Every 5 seconds, spawn interval decreases (starts at 1200ms, minimum 300ms)
  and enemy speed increases (starts at 0.003 screen-fraction per tick, max 0.012)
- Each enemy has a random speed variance of ±30%
- Each enemy has a random size between 36–52px

──────────────────────────────────────────
COLLISION DETECTION
──────────────────────────────────────────
Use circle-circle collision math (dart:math) based on normalized X/Y positions.
Player hit radius is 45% of player size.
Enemy radius is 55% of their individual size.

──────────────────────────────────────────
ANIMATIONS & FEEDBACK
──────────────────────────────────────────
- On game over: elastic screen shake using AnimationController + sin() for 400ms
- Start screen: pulsing scale animation (0.95–1.05) using repeat(reverse: true)
- Player has a cyan glow shadow beneath it
- Haptic feedback (HapticFeedback.heavyImpact()) on death

──────────────────────────────────────────
UI & VISUALS
──────────────────────────────────────────
- Deep space dark background using a 3-stop vertical LinearGradient
  (#0D0D2B → #1A1A4E → #0D1B3E)
- 35 randomly placed background star emojis (⭐ ✨ 🌟 💫) for atmosphere
- A glowing ground strip at the bottom using a transparent-to-blue gradient
- HUD showing live score (⭐) and high score (🏆) in pill-shaped chips 
  with colored borders
- Score formatted as 1.2k when over 1000
- Start overlay with game title, subtitle, emoji showcase, and a glowing 
  cyan "TAP TO START 🚀" button
- Game over overlay showing score, best score, "New High Score! 🎉" if 
  applicable, and a green "PLAY AGAIN 🔄" button
- All overlays are semi-transparent dark containers centered on screen

──────────────────────────────────────────
TECHNICAL REQUIREMENTS
──────────────────────────────────────────
- Zero external dependencies — Flutter SDK only
  (dart:async, dart:math, package:flutter/material.dart, 
   package:flutter/services.dart)
- Lock orientation to portrait using SystemChrome.setPreferredOrientations
- Use LayoutBuilder to cache screen size for normalized coordinate math
- Game loop runs at ~60fps using Timer.periodic with 16ms interval
- Enemy spawning uses recursive Timer scheduling to respect dynamic 
  interval changes
- All three timers (game loop, spawn, difficulty) are cancelled on 
  game over or restart
- Use TickerProviderStateMixin for animation controllers

──────────────────────────────────────────
ALSO GENERATE
──────────────────────────────────────────
1. pubspec.yaml
   - App name: emoji_dodger
   - No external dependencies
   - Flutter >=3.10.0, Dart >=3.0.0

2. README.md for GitHub with:
   - Badges (Flutter, Dart, Platform, License)
   - Gameplay ASCII art
   - Features list
   - Getting started instructions (clone, pub get, run, build)
   - Controls table
   - Project structure tree
   - Game mechanics parameters table
   - Contributing section with feature ideas checklist

3. TOOLS.md with:
   - AI used (model name, platform, role)
   - Language and framework breakdown
   - Every Flutter widget and feature used
   - Game design concepts explained
   - Platform support table
   - Project stats (lines of code, deps, assets, time to generate)

4. PROMPT.md with:
   - The original one-line prompt
   - This full detailed prompt
   - Follow-up prompts used
   - Tips for customizing the game
```

---

## 💬 Follow-Up Prompts Used

These were the follow-up messages sent after the first prompt to complete the project:

```
1. "create a readme file for github"

2. "give me my prompt in details for sharing others"

3. "also give me tools file like what which tech and which ai used"

4. "also give me prompt.md file"
```

---

## 🎨 Customization Prompts

Want to modify the game? Try these prompts on top of the generated code:

```
# Change the player emoji
"Change the player emoji from 🧑 to 🚀 and update the glow color to orange"

# Add sound effects
"Add sound effects using the audioplayers package — a whoosh when enemies 
spawn and an explosion sound on game over"

# Add a shield power-up
"Add a shield power-up 🛡️ that occasionally falls and gives the player 
3 seconds of invincibility when collected"

# Add lives system
"Replace instant game over with a 3-lives system, showing ❤️❤️❤️ in 
the HUD, and flash the screen red on each hit"

# Add difficulty modes
"Add a difficulty selection screen before the game with Easy / Normal / 
Hard modes that change starting speed and spawn rate"

# Persistent high score
"Add persistent high score using the shared_preferences package so it 
saves between app sessions"

# Add a leaderboard
"Integrate Firebase Firestore to store top 10 scores as a global 
leaderboard shown on the game over screen"

# Improve visuals
"Add a particle explosion effect when the player gets hit using 
Flutter's CustomPainter"
```

---

## 📋 Prompt Tips for Best Results

| Tip | Why It Helps |
|---|---|
| Be specific about file structure | Claude generates cleaner, production-ready code |
| Mention zero dependencies | Forces use of built-in Flutter/Dart only |
| List exact color hex codes | Ensures consistent theme |
| Specify animation curves by name | `elasticIn`, `easeInOut` produce better results |
| Ask for all files in one prompt | Saves follow-up messages |
| Mention target Flutter version | Avoids deprecated API usage |

---

## 🤖 AI Details

| Field | Info |
|---|---|
| **AI Model** | Claude Sonnet 4.6 |
| **Provider** | Anthropic |
| **Interface** | [claude.ai](https://claude.ai) |
| **Total prompts** | 5 (1 game + 4 follow-ups) |
| **Total time** | < 5 minutes |
| **Manual code written** | 0 lines |

---

## 📁 Files Generated by This Prompt

```
emoji_dodger/
├── lib/
│   └── main.dart       ← Full game (~370 lines)
├── pubspec.yaml        ← Project config
├── README.md           ← GitHub documentation
├── TOOLS.md            ← Tech & AI breakdown
└── PROMPT.md           ← This file
```

---

<p align="center">
  🤖 Generated with <strong>Claude Sonnet 4.6</strong> by <strong>Anthropic</strong>
  &nbsp;|&nbsp;
  💙 Built with <strong>Flutter</strong>
  &nbsp;|&nbsp;
  ✍️ 0 lines written manually
</p>
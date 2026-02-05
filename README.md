# 🎯 Pivot Coach - 100% Swift Native

Application macOS native de coaching commercial IA, 100% offline.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SwiftUI OVERLAY (NSPanel)                    │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────────────┐  │
│  │ Transcription│ │ Suggestion   │ │ Analyse Client          │  │
│  │ Live         │ │ Commerciale  │ │ Closing % │ Objections  │  │
│  └──────────────┘ └──────────────┘ └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────────────┐
│                    SWIFT NATIVE LAYER                            │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │ Audio Capture  │  │ Whisper.cpp    │  │ Ollama Client    │   │
│  │ ScreenCapture  │→ │ STT Local      │→ │ LLM HTTP API     │   │
│  │ Kit            │  │ (via Process)  │  │                  │   │
│  └────────────────┘  └────────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Prérequis

- **macOS 13.0+** (Ventura ou plus récent)
- **Xcode 15+**
- **Ollama** installé et en cours d'exécution
- **whisper.cpp** compilé avec le modèle `ggml-base.bin`

## Installation

### 1. Installer les dépendances

```bash
# Ollama
brew install ollama
ollama serve &
ollama pull mistral:7b-instruct-q4_K_M

# Whisper.cpp
cd ~
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make -j
./models/download-ggml-model.sh base
```

### 2. Ouvrir dans Xcode

```bash
cd pivot-coach-swift
open PivotCoach.xcodeproj
```

Ou créer un nouveau projet Xcode:
1. File → New → Project → macOS → App
2. Nom: PivotCoach
3. Interface: SwiftUI
4. Language: Swift
5. Copier les fichiers de `Sources/` dans le projet

### 3. Configurer les Capabilities

Dans Xcode, aller dans le target → Signing & Capabilities:
- ✅ Hardened Runtime
- ✅ Audio Input (com.apple.security.device.audio-input)

### 4. Configurer les permissions

Le fichier `Info.plist` contient déjà:
- `NSMicrophoneUsageDescription`
- `NSScreenCaptureUsageDescription`

### 5. Build & Run

```bash
# Via Xcode
Cmd + R

# Ou via command line
xcodebuild -scheme PivotCoach -configuration Release build
```

## Structure du projet

```
PivotCoach/
├── Sources/
│   ├── PivotCoachApp.swift      # Point d'entrée + AppDelegate
│   ├── ContentView.swift        # UI principale
│   ├── AudioCaptureManager.swift # Capture audio (mic + système)
│   ├── WhisperManager.swift     # Intégration whisper.cpp
│   ├── OllamaClient.swift       # Client HTTP Ollama
│   └── CoachState.swift         # État global de l'app
├── Info.plist
└── Resources/
```

## Composants

### AudioCaptureManager
- Capture microphone via `AVAudioEngine`
- Capture audio système via `ScreenCaptureKit` (macOS 13+)
- Resampling automatique à 16kHz pour Whisper
- Buffer circulaire avec overlap pour transcription continue

### WhisperManager
- Exécute `whisper.cpp` en subprocess
- Génère des fichiers WAV temporaires
- Transcription en français (`-l fr`)
- Support des modèles: base, small, medium

### OllamaClient
- Communication HTTP avec Ollama (localhost:11434)
- Prompt système optimisé pour coaching commercial
- Parsing JSON des réponses LLM
- Support streaming (optionnel)

### Overlay UI
- `NSPanel` avec `nonactivatingPanel` (ne prend pas le focus)
- `alwaysOnTop` + `visibleOnAllWorkspaces`
- Vibrancy macOS native (`NSVisualEffectView`)
- Design cohérent avec macOS

## Configuration avancée

### Changer le modèle Ollama

Dans `OllamaClient.swift`:
```swift
@Published var currentModel = "llama3:8b"  // ou "qwen2:7b"
```

### Changer le modèle Whisper

Télécharger un modèle plus grand:
```bash
cd ~/whisper.cpp
./models/download-ggml-model.sh small  # ou medium
```

Puis modifier `WhisperManager.swift` pour pointer vers le bon fichier.

### Personnaliser le prompt

Modifier `systemPrompt` dans `OllamaClient.swift` pour adapter le coaching à votre contexte.

## Dépannage

### "Ollama non connecté"
```bash
# Vérifier que Ollama tourne
curl http://localhost:11434/api/tags

# Redémarrer
pkill ollama
ollama serve
```

### "Whisper non trouvé"
```bash
# Compiler whisper.cpp
cd ~/whisper.cpp
make clean && make -j

# Vérifier le binaire
./main --help
```

### Pas de transcription
- Vérifier les permissions microphone dans Préférences Système
- Accorder l'accès "Enregistrement d'écran" pour la capture audio système

## Roadmap

- [ ] Intégration whisper.cpp native (sans subprocess)
- [ ] RAG avec cache HubSpot local
- [ ] Raccourcis clavier globaux
- [ ] Mode minimal (micro-overlay)
- [ ] Export conversation PDF
- [ ] Intégration calendrier

## Licence

Propriétaire - Pivot Inc.

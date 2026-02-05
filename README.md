# Pivot Coach

Application macOS de coaching commercial IA en temps réel.

## 🎯 Fonctionnalités

- **Overlay always-on-top** — Fenêtre flottante toujours visible
- **Capture audio système** — Écoute les appels (ScreenCaptureKit)
- **Transcription locale** — WhisperKit, 100% offline
- **LLM local** — Ollama, suggestions en temps réel
- **RAG** — Contexte client depuis HubSpot
- **Privacy-first** — Tout tourne en local

## 📋 Prérequis

### 1. Installer Ollama

```bash
brew install ollama
ollama serve
ollama pull qwen2.5:7b-instruct-q4_K_M
```

### 2. macOS 13+ (Ventura ou plus récent)

Requis pour ScreenCaptureKit audio.

## 🚀 Installation

### Option A: Depuis Xcode

1. **Ouvrir Xcode** (15.0+)
2. **File → New → Project**
3. Choisir **macOS → App**
4. Configurer:
   - Product Name: `PivotCoach`
   - Team: (ton compte)
   - Organization: `ca.pivotapp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ❌ Décocher "Include Tests"

5. **Ajouter WhisperKit:**
   - File → Add Package Dependencies
   - URL: `https://github.com/argmaxinc/WhisperKit`
   - Version: Up to Next Major

6. **Copier les fichiers:**
   - Remplacer le contenu de `PivotCoachApp.swift` par celui dans `PivotCoach/App/`
   - Créer les dossiers: Views, ViewModels, Services, Models, Utilities
   - Copier tous les fichiers Swift

7. **Configurer Info.plist:**
   - Ajouter les clés de `Info.plist` (permissions micro + screen capture)

8. **Désactiver App Sandbox:**
   - Target → Signing & Capabilities
   - Supprimer "App Sandbox" (requis pour ScreenCaptureKit)

9. **Build & Run:** `Cmd + R`

### Option B: Script rapide

```bash
# Clone le projet
cd ~/Desktop

# Ouvre Xcode et crée le projet manuellement
# Puis copie les fichiers depuis ce dossier
```

## 🔧 Configuration

### Permissions requises

Au premier lancement, macOS demandera:
1. **Microphone** — Accepter
2. **Screen Recording** — Accepter (pour l'audio système)

### Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `⌘⇧L` | Démarrer/Arrêter l'écoute |
| `⌘⇧O` | Afficher/Masquer l'overlay |
| `⌘⇧C` | Copier la suggestion |
| `⌘⇧S` | Mode discret |

## 📁 Structure

```
PivotCoach/
├── App/
│   ├── PivotCoachApp.swift      # Entry point
│   └── AppDelegate.swift        # Setup overlay + permissions
├── Views/
│   ├── OverlayWindowController.swift  # NSPanel always-on-top
│   ├── OverlayView.swift        # SwiftUI UI
│   └── SettingsView.swift       # Préférences
├── ViewModels/
│   └── CoachViewModel.swift     # État global + logique
├── Services/
│   ├── Audio/
│   │   └── SystemAudioCapture.swift   # ScreenCaptureKit
│   ├── Transcription/
│   │   └── WhisperService.swift       # WhisperKit STT
│   ├── LLM/
│   │   └── OllamaService.swift        # Ollama HTTP
│   └── RAG/
│       ├── EmbeddingService.swift     # NaturalLanguage
│       └── VectorStore.swift          # SQLite vector DB
├── Models/
│   └── Contact.swift            # Data models
├── Utilities/
│   └── KeyboardShortcuts.swift  # Global hotkeys
└── Info.plist                   # Permissions
```

## 🔌 HubSpot (optionnel)

Pour connecter HubSpot:
1. Créer une app sur [HubSpot Developer](https://developers.hubspot.com/)
2. Copier le Client ID
3. Ouvrir Settings → HubSpot → Connecter

## ⚠️ Troubleshooting

### "Ollama non disponible"
```bash
# Vérifie qu'Ollama tourne
curl http://localhost:11434/api/tags

# Si non, lance-le
ollama serve
```

### "Permission refusée"
- System Settings → Privacy & Security → Screen Recording
- Activer "PivotCoach"
- Relancer l'app

### Pas de transcription
- Vérifie que WhisperKit a téléchargé le modèle (~150MB)
- Première utilisation = téléchargement automatique

## 📄 License

Propriétaire — Pivot Inc.

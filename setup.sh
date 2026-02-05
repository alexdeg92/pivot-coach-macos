#!/bin/bash
set -e

echo "🚀 Pivot Coach - Installation automatique"
echo "=========================================="

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Vérifier Xcode
echo -e "\n${YELLOW}[1/5] Vérification de Xcode...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode n'est pas installé. Installe-le depuis l'App Store.${NC}"
    exit 1
fi
XCODE_VERSION=$(xcodebuild -version | head -1)
echo -e "${GREEN}✅ $XCODE_VERSION${NC}"

# 2. Vérifier/Installer Ollama
echo -e "\n${YELLOW}[2/5] Vérification d'Ollama...${NC}"
if ! command -v ollama &> /dev/null; then
    echo "📦 Installation d'Ollama via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}❌ Homebrew n'est pas installé. Installe-le d'abord:${NC}"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    brew install ollama
fi
echo -e "${GREEN}✅ Ollama installé${NC}"

# 3. Démarrer Ollama et télécharger le modèle
echo -e "\n${YELLOW}[3/5] Configuration d'Ollama...${NC}"
# Démarrer Ollama en background s'il ne tourne pas
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "🔄 Démarrage d'Ollama..."
    ollama serve &
    sleep 3
fi

# Vérifier si le modèle est déjà téléchargé
if ! ollama list | grep -q "qwen2.5:7b"; then
    echo "📥 Téléchargement du modèle qwen2.5:7b (peut prendre quelques minutes)..."
    ollama pull qwen2.5:7b-instruct-q4_K_M
fi
echo -e "${GREEN}✅ Ollama prêt avec qwen2.5:7b${NC}"

# 4. Créer le projet Xcode
echo -e "\n${YELLOW}[4/5] Création du projet Xcode...${NC}"

PROJECT_DIR="$HOME/Desktop/PivotCoach"
mkdir -p "$PROJECT_DIR"

# Copier les fichiers sources
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp -r "$SCRIPT_DIR/PivotCoach/"* "$PROJECT_DIR/"

# Créer le fichier projet Xcode via xcodegen ou manuellement
cat > "$PROJECT_DIR/project.yml" << 'EOF'
name: PivotCoach
options:
  bundleIdPrefix: ca.pivotapp
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"
settings:
  SWIFT_VERSION: "5.9"
  MACOSX_DEPLOYMENT_TARGET: "13.0"
targets:
  PivotCoach:
    type: application
    platform: macOS
    sources:
      - path: .
        excludes:
          - project.yml
          - "*.md"
          - Info.plist
    info:
      path: Info.plist
    settings:
      INFOPLIST_FILE: Info.plist
      PRODUCT_BUNDLE_IDENTIFIER: ca.pivotapp.coach
      CODE_SIGN_STYLE: Automatic
      ENABLE_HARDENED_RUNTIME: YES
      PRODUCT_NAME: "Pivot Coach"
    dependencies:
      - package: WhisperKit
packages:
  WhisperKit:
    url: https://github.com/argmaxinc/WhisperKit
    from: "0.9.0"
EOF

# Vérifier si xcodegen est installé
if command -v xcodegen &> /dev/null; then
    echo "🔨 Génération du projet Xcode avec XcodeGen..."
    cd "$PROJECT_DIR"
    xcodegen generate
    echo -e "${GREEN}✅ Projet Xcode créé: $PROJECT_DIR/PivotCoach.xcodeproj${NC}"
else
    echo -e "${YELLOW}⚠️ XcodeGen non installé. Installation...${NC}"
    brew install xcodegen
    cd "$PROJECT_DIR"
    xcodegen generate
    echo -e "${GREEN}✅ Projet Xcode créé: $PROJECT_DIR/PivotCoach.xcodeproj${NC}"
fi

# 5. Ouvrir dans Xcode
echo -e "\n${YELLOW}[5/5] Ouverture dans Xcode...${NC}"
open "$PROJECT_DIR/PivotCoach.xcodeproj"

echo -e "\n${GREEN}=========================================="
echo "✅ Installation terminée!"
echo "==========================================${NC}"
echo ""
echo "📍 Projet: $PROJECT_DIR"
echo ""
echo "⚠️  ÉTAPES MANUELLES REQUISES dans Xcode:"
echo "   1. Sélectionne ton Team dans Signing & Capabilities"
echo "   2. Retire 'App Sandbox' (clic sur le X)"
echo "   3. Cmd+R pour lancer"
echo ""
echo "🎙️  Au premier lancement, autorise:"
echo "   - Microphone"
echo "   - Screen Recording (pour l'audio système)"
echo ""
echo "📖 Raccourcis:"
echo "   ⌘⇧L = Start/Stop écoute"
echo "   ⌘⇧O = Afficher/Masquer overlay"
echo ""

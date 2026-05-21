#!/usr/bin/env bash
# Setup script — theodo-ans-gap-analysis V0.1
# Onboarding d'un PM Theodo : vérifie les dépendances, configure gws CLI, 1Password CLI,
# Playwright. Ne configure pas le plugin Claude Code lui-même (= /plugin install fait par l'utilisateur).

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Setup theodo-ans-gap-analysis V0.1 ===${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1. Vérification dépendances système
# ---------------------------------------------------------------------------

check_cmd() {
    local cmd=$1
    local install_hint=$2
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$("$cmd" --version 2>&1 | head -1 || echo "version unknown")
        echo -e "  ${GREEN}✓${NC} $cmd : $version"
    else
        echo -e "  ${RED}✗${NC} $cmd manquant — $install_hint"
        return 1
    fi
}

echo "1. Dépendances système"
check_cmd python3 "brew install python@3.12" || exit 1
check_cmd node "brew install node@20" || exit 1
check_cmd pdftotext "brew install poppler" || exit 1
check_cmd jq "brew install jq" || exit 1
check_cmd op "brew install --cask 1password-cli" || echo -e "  ${YELLOW}⚠${NC} 1Password CLI optionnel mais recommandé pour creds testing"

echo ""

# ---------------------------------------------------------------------------
# 2. Python deps (openpyxl pour XLSX builder)
# ---------------------------------------------------------------------------

echo "2. Dépendances Python"
if python3 -c "import openpyxl" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} openpyxl installé"
else
    echo "  Installation openpyxl..."
    pip3 install --user openpyxl
    echo -e "  ${GREEN}✓${NC} openpyxl installé"
fi
echo ""

# ---------------------------------------------------------------------------
# 3. Playwright
# ---------------------------------------------------------------------------

echo "3. Playwright"
if [[ ! -d "$HOME/.cache/ms-playwright" ]]; then
    echo "  Installation Playwright + browsers..."
    npm install -g @playwright/test
    npx playwright install chromium
    echo -e "  ${GREEN}✓${NC} Playwright installé (chromium)"
else
    echo -e "  ${GREEN}✓${NC} Playwright déjà installé"
fi
echo ""

# ---------------------------------------------------------------------------
# 4. gws CLI (Theodo Workspace)
# ---------------------------------------------------------------------------

echo "4. gws CLI (Theodo Workspace)"
if command -v gws >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} gws CLI disponible"
    if gws auth status 2>&1 | grep -q "authenticated"; then
        echo -e "  ${GREEN}✓${NC} gws authentifié sur le compte Theodo"
    else
        echo -e "  ${YELLOW}⚠${NC} gws non authentifié — lance : gws auth login"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} gws CLI manquant — voir documentation interne Theodo"
fi
echo ""

# ---------------------------------------------------------------------------
# 5. Référentiel ANS source
# ---------------------------------------------------------------------------

echo "5. Référentiel ANS DMN V1.2.2 source"
REFERENTIEL_DEFAULT="$HOME/Downloads/Exigences_referentiel_FR_DMN_V1.2.2_1_(2) (1).xlsx"
if [[ -f "$REFERENTIEL_DEFAULT" ]]; then
    echo -e "  ${GREEN}✓${NC} Référentiel trouvé : $REFERENTIEL_DEFAULT"
else
    echo -e "  ${YELLOW}⚠${NC} Référentiel attendu à : $REFERENTIEL_DEFAULT"
    echo "      Télécharge la dernière version sur :"
    echo "      https://esante.gouv.fr/produits-services/dispositifs-medicaux-numeriques"
    echo ""
    echo "      Ou exporte la variable d'env ANS_REFERENTIEL_SRC=/chemin/vers/referentiel.xlsx"
fi
echo ""

# ---------------------------------------------------------------------------
# 6. Folder missions local (cache des PDFs Drive)
# ---------------------------------------------------------------------------

echo "6. Folder missions local"
mkdir -p "$HOME/missions"
echo -e "  ${GREEN}✓${NC} $HOME/missions/ créé (cache Drive)"
echo ""

# ---------------------------------------------------------------------------
# 7. Vérification du plugin Claude Code
# ---------------------------------------------------------------------------

echo "7. Plugin Claude Code"
if [[ -d "$HOME/.claude/plugins" ]] && find "$HOME/.claude/plugins" -name "theodo-ans-gap-analysis*" 2>/dev/null | grep -q .; then
    echo -e "  ${GREEN}✓${NC} Plugin théoriquement installé"
else
    echo -e "  ${YELLOW}⚠${NC} Plugin pas encore installé"
    echo "      Dans Claude Code, lance :"
    echo "      /plugin marketplace add github:nicolasbertrand-QARA/theodo-ans-plugin"
    echo "      /plugin install theodo-ans-gap-analysis"
fi
echo ""

# ---------------------------------------------------------------------------
# Récap
# ---------------------------------------------------------------------------

echo -e "${GREEN}=== Setup terminé ===${NC}"
echo ""
echo "Prochaines étapes :"
echo "  1. Si gws non authentifié : gws auth login"
echo "  2. Si plugin non installé : ouvre Claude Code et lance /plugin install"
echo "  3. Pour démarrer une mission : /ans-init <client-slug>"
echo ""
echo "Documentation : ~/theodo-ans-plugin/README.md"
echo "Roadmap V0.1 → V1 GA : ~/theodo-ans-plugin/ROADMAP.md"

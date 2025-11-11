#!/bin/sh
# ================================================================
# sync-upstream.sh
# Sincroniza o repositório local com o upstream oficial (OISF/suricata)
# Mantém o main atualizado e preserva branches customizadas
# ================================================================

set -e

# Configurações
MAIN_BRANCH="main"
UPSTREAM_REMOTE="upstream"
ORIGIN_REMOTE="origin"

echo "=== 🌀 Iniciando sincronização com $UPSTREAM_REMOTE/$MAIN_BRANCH ==="
echo

# Garante que estamos dentro de um repositório git válido
if [ ! -d .git ]; then
    echo "❌ Este diretório não é um repositório Git."
    exit 1
fi

# Busca as atualizações do upstream e do origin
echo "📥 Atualizando remotes..."
git fetch "$UPSTREAM_REMOTE" --prune
git fetch "$ORIGIN_REMOTE" --prune
echo

# Troca para o branch principal
echo "🔀 Trocando para branch '$MAIN_BRANCH'..."
git checkout "$MAIN_BRANCH"

# Garante que não há mudanças locais
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "⚠️  Existem mudanças não commitadas. Faça commit ou stash antes de sincronizar."
    exit 1
fi

# Rebasa o main local com o upstream/main
echo "📦 Atualizando $MAIN_BRANCH com $UPSTREAM_REMOTE/$MAIN_BRANCH..."
git rebase "$UPSTREAM_REMOTE/$MAIN_BRANCH"

# Se quiser mesclar em vez de rebase, use:
# git merge --ff-only "$UPSTREAM_REMOTE/$MAIN_BRANCH"

# Atualiza o origin (GitHub)
echo "🚀 Enviando atualizações para $ORIGIN_REMOTE/$MAIN_BRANCH..."
git push "$ORIGIN_REMOTE" "$MAIN_BRANCH"

echo
echo "✅ Sincronização concluída com sucesso!"
echo "-------------------------------------------"
echo "Agora seu '$MAIN_BRANCH' está alinhado com o upstream."
echo "Você pode rebasear suas branches customizadas, ex:"
echo
echo "  git checkout freebsd-alertpf"
echo "  git rebase main"
echo
echo "-------------------------------------------"

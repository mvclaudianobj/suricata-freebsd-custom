#!/bin/sh
PKG_DIR="/root/suricata-freebsd-custom"
PKG_NAME="suricata"

# Detectar informações do sistema
PKG_VERSION="7.0.13"
OS_NAME="FreeBSD"
OS_VERSION=$(uname -r | cut -d'-' -f1)  # 15.0
ARCH=$(uname -m)                         # amd64

# Nome do pacote no formato limpo
PKG_FILENAME="${PKG_NAME}-${PKG_VERSION}-build-${OS_NAME}_${OS_VERSION}-${ARCH}.pkg"

echo "🔍 Detectando sistema:"
echo "   Versão: $PKG_VERSION"
echo "   Sistema: $OS_NAME $OS_VERSION"
echo "   Arch: $ARCH"
echo "   Pacote: $PKG_FILENAME"
echo ""

# LIMPAR COMPLETAMENTE
echo "🧹 Limpando diretório $PKG_DIR..."
rm -rf $PKG_DIR
mkdir -p $PKG_DIR

# Criar estrutura
mkdir -p $PKG_DIR/usr/local/bin
mkdir -p $PKG_DIR/usr/local/etc/suricata
mkdir -p $PKG_DIR/usr/local/share/suricata/rules
mkdir -p $PKG_DIR/opt/testlibc/lib

# Copiar binários
echo "📦 Copiando binários..."
cp /usr/local/bin/suricata $PKG_DIR/usr/local/bin/
cp /usr/local/bin/suricatasc $PKG_DIR/usr/local/bin/
cp /usr/local/bin/suricatactl $PKG_DIR/usr/local/bin/

# Copiar bibliotecas
echo "📚 Copiando bibliotecas..."
ldd /usr/local/bin/suricata | grep "/usr/local" | awk '{print $3}' | while read lib; do
    [ -f "$lib" ] && cp "$lib" $PKG_DIR/opt/testlibc/lib/ && echo "  ✅ $lib"
done

# Copiar configurações
echo "⚙️  Copiando configurações..."
cp /usr/local/etc/suricata/suricata.yaml $PKG_DIR/usr/local/etc/suricata/ 2>/dev/null || echo "  ⚠️  suricata.yaml não encontrado"
cp /usr/local/share/suricata/classification.config $PKG_DIR/usr/local/etc/suricata/ 2>/dev/null || echo "  ⚠️  classification.config não encontrado"
cp /usr/local/share/suricata/reference.config $PKG_DIR/usr/local/etc/suricata/ 2>/dev/null || echo "  ⚠️  reference.config não encontrado"

# Copiar regras
echo "📋 Copiando regras..."
cp -r /usr/local/share/suricata/rules/* $PKG_DIR/usr/local/share/suricata/rules/ 2>/dev/null || echo "  ⚠️  regras não encontradas"

# Criar suricata-wrapper
cat > $PKG_DIR/usr/local/bin/suricata-wrapper << 'EOF'
#!/bin/sh
export LD_LIBRARY_PATH=/opt/testlibc/lib
exec /usr/local/bin/suricata "$@"
EOF

# Permissões
chmod +x $PKG_DIR/usr/local/bin/suricata*
chmod +x $PKG_DIR/usr/local/bin/suricata-wrapper

# Criar arquivo de informações do build
cat > $PKG_DIR/BUILD_INFO.txt << EOF
Suricata Custom Build
=====================
Package: $PKG_FILENAME
Version: $PKG_VERSION
Build Date: $(date)
Build System: $(uname -a)

Target Platform:
- OS: $OS_NAME $OS_VERSION
- Architecture: $ARCH
- CPU: $(sysctl -n hw.model)

Features Included:
- QUIC Protocol Support
- Hyperscan Acceleration
- GeoIP Support  
- IPFW & Netmap Support
- Rust Integration
- Isolated Libraries in /opt/testlibc/lib

Installation:
  tar -xJf $PKG_FILENAME -C /

Usage:
  suricata-wrapper --version
  LD_LIBRARY_PATH=/opt/testlibc/lib suricata --version

Maintainer: Custom Build
EOF

# --- CRIAR PACOTE MANUALMENTE ---
mkdir -p /root/pkg_build
cd /root/pkg_build

echo "📦 Criando pacote..."
tar -c -J -f "$PKG_FILENAME" -C $PKG_DIR .

echo ""
echo "✅ PACOTE CRIADO COM SUCESSO!"
echo "📦 Arquivo: /root/pkg_build/$PKG_FILENAME"
echo "📊 Tamanho: $(du -h "$PKG_FILENAME" | awk '{print $1}')"
echo "📁 Arquivos: $(tar -tf "$PKG_FILENAME" | wc -l)"

# Verificar conteúdo
echo ""
echo "🧪 VERIFICANDO CONTEÚDO:"
echo "=== /usr/local/bin ==="
tar -tf "$PKG_FILENAME" | grep "^usr/local/bin" | head -5
echo ""
echo "=== /opt/testlibc/lib ==="
tar -tf "$PKG_FILENAME" | grep "^opt/testlibc/lib" | head -5

# --- CRIAR SCRIPT DE INSTALAÇÃO AUTOMATICAMENTE ---
cat > /root/pkg_build/install_suricata.sh << 'EOF'
#!/bin/sh
# install_suricata.sh - Suricata Custom Installer
# Generated automatically during package creation

PKG_FILE="$1"
if [ -z "$PKG_FILE" ]; then
    echo "❌ Uso: $0 <suricata-*.pkg>"
    echo ""
    echo "📦 Pacotes disponíveis:"
    ls suricata-*.pkg 2>/dev/null || echo "   Nenhum pacote encontrado"
    exit 1
fi

# Verificar se o arquivo existe
if [ ! -f "$PKG_FILE" ]; then
    echo "❌ Arquivo não encontrado: $PKG_FILE"
    exit 1
fi

echo "🔄 Instalando Suricata..."
echo "   Pacote: $(basename "$PKG_FILE")"

# Extrair
tar -xJf "$PKG_FILE" -C /

echo "🔧 Configurando permissões..."
chmod +x /usr/local/bin/suricata* 2>/dev/null || true

echo "🧪 Verificando instalação..."
if [ -x "/usr/local/bin/suricata-wrapper" ]; then
    echo "✅ Testando suricata-wrapper..."
    /usr/local/bin/suricata-wrapper --version
else
    echo "✅ Testando binário direto..."
    LD_LIBRARY_PATH="/opt/testlibc/lib" /usr/local/bin/suricata --version
fi

echo ""
echo "🎉 Instalação concluída!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Configurar interfaces: editar /usr/local/etc/suricata/suricata.yaml"
echo "   2. Testar configuração: suricata-wrapper -T -c /usr/local/etc/suricata/suricata.yaml"
echo "   3. Executar: suricata-wrapper -c /usr/local/etc/suricata/suricata.yaml"
echo ""
echo "💡 DICAS:"
echo "   - Use 'suricata-wrapper' para configuração automática das bibliotecas"
echo "   - Verifique as regras em /usr/local/share/suricata/rules/"
echo "   - Consulte BUILD_INFO.txt para detalhes do build"
EOF

# Dar permissão ao script de instalação
chmod +x /root/pkg_build/install_suricata.sh

echo ""
echo "🔧 SCRIPT DE INSTALAÇÃO CRIADO:"
echo "   /root/pkg_build/install_suricata.sh"
echo ""
echo "📝 PARA INSTALAR:"
echo "   cd /root/pkg_build"
echo "   ./install_suricata.sh $PKG_FILENAME"
echo ""
echo "🎯 PARA USAR:"
echo "   suricata-wrapper --version"
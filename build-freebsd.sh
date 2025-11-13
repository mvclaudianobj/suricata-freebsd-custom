#!/bin/sh
# ==========================================================
# Suricata FreeBSD Build Script - Versão LibHTP Corrigida
# ==========================================================

set -e

echo ">>> [0/6] Preparando ambiente de build..."
export CFLAGS="-Os -s -ffunction-sections -fdata-sections -march=native"
export LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -L/usr/local/lib -lpfctl -lnv"
export CPPFLAGS="-I/usr/local/include -I./libpfctl/include"
export RUSTFLAGS="-C opt-level=z -C panic=abort"

# ==========================================================
# 1. Compilar libhtp usando método correto
# ==========================================================
echo ">>> [1/5] Compilando libhtp..."
if [ -d "./libhtp" ]; then
  cd libhtp
  
  # Método 1: Usar autogen.sh se existir
  if [ -f "autogen.sh" ]; then
    echo ">>> Executando autogen.sh..."
    ./autogen.sh
  else
    # Método 2: Gerar arquivos manualmente
    echo ">>> Gerando arquivos de configuração..."
    aclocal
    autoheader
    automake --add-missing --copy
    autoconf
  fi
  
  echo ">>> Configurando libhtp..."
  ./configure --prefix=/usr/local
  
  echo ">>> Compilando libhtp..."
  make -j$(sysctl -n hw.ncpu)
  
  echo ">>> Instalando libhtp..."
  make install
  
  cd ..
  echo "✅ libhtp compilado e instalado com sucesso!"
else
  echo "❌ Diretório libhtp não encontrado!"
  exit 1
fi

# ==========================================================
# 2. Configurar Suricata
# ==========================================================
echo ">>> [2/5] Configurando Suricata..."
autoreconf -fi

./configure \
  --prefix=/usr/local \
  --sysconfdir=/usr/local/etc/suricata \
  --localstatedir=/var \
  --enable-rust \
  --enable-pf-var \
  --enable-alert-pf \
  --enable-pcap \
  --enable-unix-socket \
  --enable-zstd \
  --enable-libjansson \
  --enable-libmagic \
  --enable-python \
  --enable-pcre-jit \
  --enable-libnet1.1 \
  --enable-luajit \
  --enable-geoip \
  --enable-http2-decompression \
  --enable-ja3 \
  --enable-ja4 \
  --enable-netmap

# ==========================================================
# 3. Compilar Suricata
# ==========================================================
echo ">>> [3/5] Compilando Suricata..."
make -j$(sysctl -n hw.ncpu)

# ==========================================================
# 4. Instalar Suricata
# ==========================================================
echo ">>> [4/5] Instalando Suricata..."
make install

# ==========================================================
# 5. Verificação
# ==========================================================
echo ">>> [5/5] Verificando instalação..."
if suricata --build-info >/dev/null 2>&1; then
  echo "✅ Suricata instalado com sucesso!"
  echo ">>> Compatibilidade SIMD:"
  suricata --build-info | grep "SIMD support"
else
  echo "❌ Falha na instalação do Suricata"
  exit 1
fi

echo "🎉 Build concluído com sucesso!"
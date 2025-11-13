#!/bin/sh
# ==========================================================
# Suricata FreeBSD Build Script - Versão LibHTP Corrigida
# ==========================================================

set -e

echo ">>> [0/8] Preparando ambiente de build..."
export CFLAGS="-Os -s -ffunction-sections -fdata-sections -march=native"
export LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -L/usr/local/lib -lpfctl -lnv"
export CPPFLAGS="-I/usr/local/include -I./libpfctl/include"
export RUSTFLAGS="-C opt-level=z -C panic=abort"

# ==========================================================
# Extrair arquivos compactados
# ==========================================================
echo ">>> [1/8] Extraindo arquivos compactados..."

# Extrair libhtp.tar.gz
if [ -f "libhtp.tar.gz" ]; then
    echo ">>> Extraindo libhtp.tar.gz..."
    tar -xzf libhtp.tar.gz
    if [ ! -d "./libhtp" ]; then
        echo "❌ libhtp.tar.gz extraído mas diretório libhtp não encontrado!"
        exit 1
    fi
    echo "✅ libhtp.tar.gz extraído com sucesso!"
else
    echo "❌ libhtp.tar.gz não encontrado!"
    exit 1
fi

# Extrair libpfctl.tar.gz
if [ -f "libpfctl.tar.gz" ]; then
    echo ">>> Extraindo libpfctl.tar.gz..."
    tar -xzf libpfctl.tar.gz
    if [ ! -d "./libpfctl" ]; then
        echo "❌ libpfctl.tar.gz extraído mas diretório libpfctl não encontrado!"
        exit 1
    fi
    echo "✅ libpfctl.tar.gz extraído com sucesso!"
else
    echo "❌ libpfctl.tar.gz não encontrado!"
    exit 1
fi

# ==========================================================
# 2. Compilar libhtp usando método correto
# ==========================================================
echo ">>> [2/8] Compilando libhtp..."
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
# 3. Compilar libpfctl se necessário
# ==========================================================
echo ">>> [3/8] Verificando libpfctl..."
if [ -d "./libpfctl" ]; then
  echo ">>> Diretório libpfctl encontrado, verificando necessidade de compilação..."
  
  # Verificar se a biblioteca já existe no sistema
  if ! pkg-config --exists libpfctl 2>/dev/null && [ ! -f "/usr/local/lib/libpfctl.a" ]; then
    echo ">>> Compilando libpfctl..."
    cd libpfctl
    
    if [ -f "Makefile" ]; then
      make -j$(sysctl -n hw.ncpu)
      make install
      echo "✅ libpfctl compilado e instalado com sucesso!"
    else
      echo "⚠️  Makefile não encontrado em libpfctl, assumindo que não precisa ser compilado"
    fi
    
    cd ..
  else
    echo "✅ libpfctl já disponível no sistema"
  fi
else
  echo "❌ Diretório libpfctl não encontrado!"
  exit 1
fi

# ==========================================================
# 4. Configurar Suricata
# ==========================================================
echo ">>> [4/8] Configurando Suricata..."
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
# 5. Compilar Suricata
# ==========================================================
echo ">>> [5/8] Compilando Suricata..."
make -j$(sysctl -n hw.ncpu)

# ==========================================================
# 6. Instalar Suricata
# ==========================================================
echo ">>> [6/8] Instalando Suricata..."
make install

# ==========================================================
# 7. Configurar diretórios
# ==========================================================
echo ">>> [7/8] Configurando diretórios..."
mkdir -p /usr/local/etc/suricata
mkdir -p /var/log/suricata
mkdir -p /var/run/suricata

# ==========================================================
# 8. Verificação
# ==========================================================
echo ">>> [8/8] Verificando instalação..."
if suricata --build-info >/dev/null 2>&1; then
  echo "✅ Suricata instalado com sucesso!"
  echo ">>> Compatibilidade SIMD:"
  suricata --build-info | grep "SIMD support" || echo "⚠️  Informação SIMD não disponível"
else
  echo "❌ Falha na instalação do Suricata"
  exit 1
fi

echo "🎉 Build concluído com sucesso!"
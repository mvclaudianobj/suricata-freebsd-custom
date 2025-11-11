#!/bin/sh
# ==========================================================
# Suricata FreeBSD Custom Build Script with alert-pf support
# ==========================================================
# Build otimizado com suporte a netmap, alert-pf, Rust e JA3/JA4
# Autor: Marcos Claudiano
# Sistema: FreeBSD 15+

set -e

echo ">>> [0/6] Preparando ambiente de build..."
export CFLAGS="-Os -s -ffunction-sections -fdata-sections -march=native"
export LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -L/usr/local/lib -lpfctl -lnv"
export CPPFLAGS="-I/usr/local/include -I./libpfctl/include"
export RUSTFLAGS="-C opt-level=z -C panic=abort"

# ==========================================================
# 1. Compilar libpfctl local
# ==========================================================
echo ">>> [1/5] Compilando libpfctl..."
if [ -d "./libpfctl" ]; then
  cd libpfctl
  echo ">>> Gerando autotools da libpfctl..."
  make clean all install
  cd ..
else
  echo "❌ Diretório libpfctl não encontrado!"
  exit 1
fi

# ==========================================================
# 2. Gerar autotools do Suricata
# ==========================================================
echo ">>> [2/6] Gerando arquivos de configuração do Suricata..."
autoreconf -fi

# ==========================================================
# 3. Configurar build
# ==========================================================
echo ">>> [3/6] Configurando build do Suricata..."
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
# 4. Compilar e instalar Suricata
# ==========================================================
echo ">>> [4/6] Compilando Suricata..."
make -j$(sysctl -n hw.ncpu)
make install

# ==========================================================
# 5. Verificação final
# ==========================================================
echo ">>> [5/6] Verificação final..."
if strings "$(which suricata)" | grep -q "alert-pf"; then
  echo "✅ Compilação concluída com suporte a alert-pf!"
else
  echo "⚠️  Compilação concluída, mas alert-pf não encontrado!"
fi

# ==========================================================
# 6. Pós-build: geração de pacote
# ==========================================================
echo ">>> [6/6] Executando script de pós-build..."
if [ -x "./script_pos_build_suricata.sh" ]; then
  ./script_pos_build_suricata.sh
  echo "📦 Pacote gerado com sucesso!"
else
  echo "⚠️  script_pos_build_suricata.sh não encontrado ou sem permissão de execução!"
fi

echo "✅ Processo de build completo!"

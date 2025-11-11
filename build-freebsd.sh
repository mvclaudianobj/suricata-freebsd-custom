#!/bin/sh
# ==========================================================
# Suricata FreeBSD Custom Build Script with alert-pf support
# ==========================================================
# Build otimizado com suporte a netmap, alert-pf, Rust e JA3/JA4
# Autor: Marcos Claudiano
# Sistema: FreeBSD 15+

set -e

echo ">>> [1/4] Preparando ambiente de build..."
export CFLAGS="-Os -s -ffunction-sections -fdata-sections -march=native"
export LDFLAGS="-Wl,--gc-sections -Wl,--as-needed -L/usr/local/lib -lpfctl -lnv"
export CPPFLAGS="-I/usr/local/include -I./libpfctl/include"
export RUSTFLAGS="-C opt-level=z -C panic=abort"

echo ">>> [2/4] Gerando arquivos de configuração..."
autoreconf -fi

echo ">>> [3/4] Configurando build..."
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

echo ">>> [4/4] Compilando e instalando..."
make -j$(sysctl -n hw.ncpu)
make install

echo "✅ Compilação concluída!"
echo "Verifique suporte com: strings \$(which suricata) | grep alert-pf"

#!/bin/bash
set -euo pipefail
export TMPDIR="$PWD/.build-tmp"
mkdir -p "$TMPDIR"
[[ $(findmnt -n -o FSTYPE -T "$TMPDIR") != tmpfs ]]
root=$PWD
prefix="$root/.build-deps/usr"
toolchain="$root/.build-rust"
for component in rustc ruststd cargo; do
 [[ -f "$root/$component/install.sh" ]]
 bash "$root/$component/install.sh" --prefix="$toolchain" --disable-ldconfig
done
export PATH="$toolchain/bin:$PATH"
export CARGO_HOME="$root/.build-cargo"
export CARGO_NET_OFFLINE=true CARGO_BUILD_JOBS=2
mkdir -p "$CARGO_HOME" "$prefix/lib" "$prefix/include/tlottie" "$prefix/include/wallet_engine" \
  "$root/out/widget_helper_rust/cargo" "$root/out/widget_helper_rust/.cargo"
[[ $(rustc --version) == rustc\ 1.96.1* ]]
python3 -B - "$root" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]);text=(root/'deps/cargo-config.template').read_text()
(root/'.build-cargo/config.toml').write_text(text.replace('@VENDOR@',str(root/'deps/vendor')))
widget_vendor=root/'deps/vendor-widget'
widget_cfg=text.replace('@VENDOR@',str(widget_vendor if widget_vendor.is_dir() else root/'deps/vendor'))
for cfg_path in (
    root/'out/widget_helper_rust/cargo/config.toml',
    root/'out/widget_helper_rust/.cargo/config.toml',
):
    cfg_path.write_text(widget_cfg)
PY
cargo rustc --locked --offline --manifest-path deps/tdesktop_rust/Cargo.toml --lib --release --crate-type staticlib --crate-type cdylib
install -m644 deps/tdesktop_rust/target/release/libtdesktop_rust.a "$prefix/lib/"
install -m644 deps/tlottie/include/tlottie.h "$prefix/include/tlottie/"
pushd deps/tdesktop_rust
cargo run --locked --offline --manifest-path ../wallet-engine/bindgen/cpp/bindgen/Cargo.toml -- \
 --library --out-dir "$prefix/include/wallet_engine" \
 "$root/deps/tdesktop_rust/target/release/libtdesktop_rust.so"
popd
cmake -S deps/tg_owt -B .build-owt -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_INSTALL_LIBDIR=lib \
 -DTG_OWT_DLOPEN_PIPEWIRE=ON -DCMAKE_DISABLE_FIND_PACKAGE_absl=ON
cmake --build .build-owt --parallel 2
cmake --install .build-owt
cmake -S deps/tde2e -B .build-tde2e -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_INSTALL_LIBDIR=lib -DTD_E2E_ONLY=ON
cmake --build .build-tde2e --parallel 2
cmake --install .build-tde2e
pushd deps/rnnoise
if [[ -f src/rnnoise_data.c && -f src/rnnoise_data.h ]]; then
 autoreconf -isf
else
 ./autogen.sh
fi
./configure --prefix="$prefix" --enable-static --disable-shared
make -j2
make install
popd

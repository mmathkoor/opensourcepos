#!/usr/bin/env bash
# يبني الموقع ويشغّله على المنفذ 8080 (يعمل داخل GitHub Codespaces).
set -e
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d "$HOME/flutter" ]; then
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
  fi
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter config --enable-web >/dev/null 2>&1 || true

if [ ! -d web ]; then
  flutter create . --platforms=web --project-name dukkan --org com.dukkan
  git checkout -- lib pubspec.yaml 2>/dev/null || true
  rm -rf test
  sed -i 's|<title>.*</title>|<title>دكّان</title>|' web/index.html || true
fi

flutter pub get
flutter build web --release

echo "جاهز. افتح المنفذ 8080 من تبويب Ports."
cd build/web
python3 -m http.server 8080

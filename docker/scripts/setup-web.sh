#!/bin/sh
# Conduit Web Build Helper
# Add web platform to existing Flutter project and check plugin compatibility.

set -e

echo "=== Conduit Web Build Helper ==="
echo ""

# Detect flutter
if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found. Ensure Flutter >=3.47.0 is installed."
  echo "  Install: https://docs.flutter.dev/get-started/install"
  exit 1
fi

# Check Dart version
dart_version=$(dart --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
echo "Dart version: $dart_version"

# 1. Add web platform
echo ""
echo "📋 Adding web platform..."
if [ ! -f "web/index.html" ]; then
  flutter create --platforms=web .
  echo "   ✅ Web platform added"
else
  echo "   ℹ️  Web directory already exists"
fi

# 2. Update pubspec for web-compatible dependencies
echo ""
echo "📋 Checking web plugin compatibility..."
WEB_DEPS=""
HAS_WEB_DEPS=false

# Check which web-incompatible plugins are used and add web alternatives
if grep -q "flutter_secure_storage:" pubspec.yaml; then
  if ! grep -q "flutter_secure_storage_web" pubspec.yaml; then
    echo "   ⚠️  flutter_secure_storage needs web implementation"
    WEB_DEPS="$WEB_DEPS  flutter_secure_storage_web: ^2.1.1"
    HAS_WEB_DEPS=true
  fi
fi
if grep -q "path_provider:" pubspec.yaml; then
  if ! grep -q "path_provider_web" pubspec.yaml; then
    echo "   ⚠️  path_provider needs web implementation"
    WEB_DEPS="$WEB_DEPS  path_provider_web: ^2.2.0"
    HAS_WEB_DEPS=true
  fi
fi
if grep -q "connectivity_plus:" pubspec.yaml; then
  echo "   ✓ connectivity_plus has web support"
fi
if grep -q "share_plus:" pubspec.yaml; then
  echo "   ✓ share_plus has web support"
fi
if grep -q "url_launcher:" pubspec.yaml; then
  echo "   ✓ url_launcher has web support"
fi
if grep -q "image_picker:" pubspec.yaml; then
  echo "   ✓ image_picker has web support"
fi
if grep -q "file_picker:" pubspec.yaml; then
  echo "   ✓ file_picker has web support"
fi
if grep -q "just_audio:" pubspec.yaml; then
  echo "   ✓ just_audio has web support"
fi
if grep -q "wakelock_plus:" pubspec.yaml; then
  echo "   ✓ wakelock_plus has web support"
fi

if [ "$HAS_WEB_DEPS" = true ]; then
  echo ""
  echo "📋 Adding web dependencies to pubspec.yaml..."
  # Find proper location to insert (before dev_dependencies)
  sed -i '/^dev_dependencies:/i\  # Web platform implementations\n'"$WEB_DEPS"'\n' pubspec.yaml
  echo "   ✅ Web dependencies added"
fi

# 3. Create icon directory if missing
mkdir -p web/icons

echo ""
echo "📋 Generating placeholder icons..."
# Generate simple colored PNG icons for the web manifest
if command -v python3 >/dev/null 2>&1; then
  python3 -c "
import struct, zlib
def create_png(width, height, r, g, b, fname):
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter byte
        for x in range(width):
            raw += bytes([r, g, b, 255])
    compressed = zlib.compress(raw)
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)  # 8-bit RGBA
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', ihdr)
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    with open(fname, 'wb') as f:
        f.write(png)
for size, name in [(192, 'Icon-192.png'), (512, 'Icon-512.png'),
                    (192, 'Icon-maskable-192.png'), (512, 'Icon-maskable-512.png')]:
    create_png(size, size, 60, 100, 200, f'web/icons/{name}')
"
  echo "   ✅ Icons generated"
fi

# 4. Handle plugin incompatibilities with conditional code
echo ""
echo "📋 Checking for web-incompatible plugins..."
INCOMPATIBLE=""
grep -q "flutter_inappwebview" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE flutter_inappwebview"
grep -q "vad:" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE vad"
grep -q "local_notifications" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE local_notifications"
grep -q "home_widget" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE home_widget"
grep -q "quick_actions" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE quick_actions"
grep -q "flutter_callkit_incoming" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE flutter_callkit_incoming"
grep -q "receive_sharing_intent" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE receive_sharing_intent"
grep -q "flutter_image_compress" pubspec.yaml && INCOMPATIBLE="$INCOMPATIBLE flutter_image_compress"

if [ -n "$INCOMPATIBLE" ]; then
  echo "   ⚠️  Web-incompatible plugins detected:$INCOMPATIBLE"
  echo "   These will cause build errors on web. They need conditional imports"
  echo "   or web stubs. See docs/WEB_BUILD.md for details."
else
  echo "   ✓ No major incompatibilities detected"
fi

# 5. Clean and get dependencies
echo ""
echo "📋 Running flutter pub get..."
flutter pub get

# 6. Generate code
echo ""
echo "📋 Running build_runner..."
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5 || true

echo ""
echo "=== Setup complete ==="
echo ""
echo "To build for web:"
echo "  flutter build web --release --no-tree-shake-icons"
echo ""
echo "To test locally:"
echo "  flutter run -d chrome"
echo ""
echo "For Docker deployment:"
echo "  docker compose -f docker/docker-compose.yml build"
echo "  docker compose -f docker/docker-compose.yml up -d"
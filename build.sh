#!/usr/bin/env bash
#
# ErosionWQ Build Script
# Builds ErosionWQ.ipa with ad-hoc signing and App Group entitlements
#

set -euo pipefail
cd "$(dirname "$0")"

APPLICATION_NAME="Erosion"
OUT_IPA="ErosionWQ.ipa"

echo "=== Building $OUT_IPA ==="

# Check if xcodebuild is available
if command -v xcodebuild >/dev/null 2>&1; then
    echo "[*] Using xcodebuild to compile full project..."
    rm -rf build "$OUT_IPA"
    mkdir -p build
    cd build
    
    xcodebuild -project "../$APPLICATION_NAME.xcodeproj" \
        -scheme "$APPLICATION_NAME" \
        -configuration Release \
        -derivedDataPath "DerivedDataApp" \
        -destination 'generic/platform=iOS' \
        build \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"
        
    DD_APP_PATH="DerivedDataApp/Build/Products/Release-iphoneos/$APPLICATION_NAME.app"
    TARGET_APP="$APPLICATION_NAME.app"
    cp -r "$DD_APP_PATH" "$TARGET_APP"
    
    echo "[*] Signing with entitlements..."
    if command -v ldid >/dev/null 2>&1; then
        ldid -S"../Erosion/Erosion.entitlements" "$TARGET_APP"
    elif command -v codesign >/dev/null 2>&1; then
        codesign -f -s - --entitlements "../Erosion/Erosion.entitlements" "$TARGET_APP"
    fi
    
    echo "[*] Creating IPA package..."
    mkdir Payload
    cp -r "$TARGET_APP" Payload/
    zip -9qry "../$OUT_IPA" Payload
    
    cd ..
    rm -rf build
    echo "=== Successfully built $OUT_IPA ==="
else
    echo "[!] xcodebuild not found. Please run on macOS with Xcode installed."
    exit 1
fi

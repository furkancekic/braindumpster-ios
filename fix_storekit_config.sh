#!/bin/bash

# StoreKit Configuration Fix Script
# This script configures Xcode to use Products.storekit for IAP testing

echo "🔧 Fixing StoreKit Configuration for Braindumpster..."

# 1. Check if Products.storekit exists
if [ ! -f "/Users/furkancekic/projects/last_tasks/Products.storekit" ]; then
    echo "❌ Products.storekit not found!"
    exit 1
fi

echo "✅ Products.storekit found"

# 2. Check if file is in Xcode project
if ! grep -q "Products.storekit" "/Users/furkancekic/projects/last_tasks/Braindumpster.xcodeproj/project.pbxproj"; then
    echo "❌ Products.storekit not in Xcode project!"
    echo "   Add it manually in Xcode"
    exit 1
fi

echo "✅ Products.storekit is in Xcode project"

# 3. Update scheme to use absolute path (more reliable)
SCHEME_FILE="/Users/furkancekic/projects/last_tasks/Braindumpster.xcodeproj/xcshareddata/xcschemes/Braindumpster.xcscheme"

# Backup original scheme
cp "$SCHEME_FILE" "${SCHEME_FILE}.backup"

# Update the storeKitConfigurationFileReference to use project-relative path
sed -i '' 's|storeKitConfigurationFileReference = ".*"|storeKitConfigurationFileReference = "Products.storekit"|g' "$SCHEME_FILE"

echo "✅ Updated scheme configuration"

echo ""
echo "============================================"
echo "✅ StoreKit Configuration Fixed!"
echo "============================================"
echo ""
echo "Now do the following:"
echo ""
echo "1. Open Xcode"
echo "2. Select 'Braindumpster' scheme (top bar)"
echo "3. Product → Scheme → Edit Scheme... (or ⌘+<)"
echo "4. Select 'Run' on the left"
echo "5. Go to 'Options' tab"
echo "6. Find 'StoreKit Configuration'"
echo "7. Select 'Products' from dropdown"
echo "8. Click 'Close'"
echo ""
echo "9. Clean Build: ⌘+Shift+K"
echo "10. Run: ⌘+R"
echo ""
echo "============================================"

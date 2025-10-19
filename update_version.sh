#!/bin/bash

# Version and Build Number Update Script for TestFlight

echo "🔧 Updating Version and Build Number..."
echo ""

PROJECT_DIR="/Users/furkancekic/projects/last_tasks"
PROJECT_FILE="$PROJECT_DIR/Braindumpster.xcodeproj/project.pbxproj"

# Current Version
CURRENT_VERSION="1.0"
CURRENT_BUILD="1"

# New Version for TestFlight
NEW_VERSION="1.0"
NEW_BUILD="2"

echo "📊 Current Status:"
echo "   Version: $CURRENT_VERSION"
echo "   Build: $CURRENT_BUILD"
echo ""
echo "📈 Updating to:"
echo "   Version: $NEW_VERSION"
echo "   Build: $NEW_BUILD"
echo ""

# Backup project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Update using agvtool (if available)
cd "$PROJECT_DIR"

# Set build number
xcrun agvtool new-version -all $NEW_BUILD 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Build number updated to $NEW_BUILD using agvtool"
else
    echo "⚠️  agvtool not available, will update manually in Xcode"
fi

echo ""
echo "============================================"
echo "✅ Version Update Script Completed"
echo "============================================"
echo ""
echo "NOW DO THIS IN XCODE:"
echo ""
echo "1. Open Xcode"
echo "2. Select 'Braindumpster' project (blue icon, top of navigator)"
echo "3. Select 'Braindumpster' target"
echo "4. Go to 'General' tab"
echo "5. Update:"
echo "   • Version: $NEW_VERSION"
echo "   • Build: $NEW_BUILD"
echo ""
echo "6. Then Archive:"
echo "   • Product → Archive (⌘+B first to build)"
echo "   • Wait for archive to complete"
echo "   • Click 'Distribute App'"
echo "   • Select 'App Store Connect'"
echo "   • Select 'Upload'"
echo "   • Next → Next → Upload"
echo ""
echo "============================================"

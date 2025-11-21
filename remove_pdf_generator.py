#!/usr/bin/env python3
"""
Remove PDFGenerator.swift references from Xcode project file
"""

import re

project_file = 'Braindumpster.xcodeproj/project.pbxproj'

print("🔍 Reading project file...")
with open(project_file, 'r', encoding='utf-8') as f:
    content = f.read()

print("🗑️  Removing PDFGenerator.swift references...")

# Remove lines containing PDFGenerator.swift
lines = content.split('\n')
filtered_lines = []

for line in lines:
    if 'PDFGenerator.swift' not in line:
        filtered_lines.append(line)
    else:
        print(f"  Removing: {line.strip()[:80]}...")

content = '\n'.join(filtered_lines)

print("💾 Writing cleaned project file...")
with open(project_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Successfully removed all PDFGenerator.swift references from Xcode project")

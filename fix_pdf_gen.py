#!/usr/bin/env python3
import re

# Read the pbxproj file
with open('Braindumpster.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Use fixed IDs to avoid duplicates
file_ref_id = 'AABBCCDD112233445566778'
build_file_id = 'EEFFGGHH998877665544332'

# Check if already added
if file_ref_id in content:
    print("⚠️  PDFGenerator already in project, removing old entries...")
    # Remove old entries
    content = re.sub(r'\s*' + file_ref_id + r'.*?;', '', content)
    content = re.sub(r'\s*' + build_file_id + r'.*?;', '', content)
    content = re.sub(r'\s*CC788DFA60ED471BA6084696.*?;', '', content)
    content = re.sub(r'\s*8E99A83E3CD546CFA00CAF07.*?;', '', content)

# Add PBXBuildFile entry (after first PBXBuildFile line)
build_file_entry = f'\t\t{build_file_id} /* PDFGenerator.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* PDFGenerator.swift */; }};'
content = re.sub(
    r'(/\* Begin PBXBuildFile section \*/\n)',
    r'\1' + build_file_entry + '\n',
    content
)

# Add PBXFileReference entry (after first PBXFileReference line) 
file_ref_entry = f'\t\t{file_ref_id} /* PDFGenerator.swift */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = PDFGenerator.swift; path = Utilities/PDFGenerator.swift; sourceTree = "<group>"; }};'
content = re.sub(
    r'(/\* Begin PBXFileReference section \*/\n)',
    r'\1' + file_ref_entry + '\n',
    content
)

# Find where DidYouKnowFacts is listed and add PDFGenerator after it
content = re.sub(
    r'(AABDEED2908155770317B195 /\* DidYouKnowFacts.swift \*/,)',
    r'\1\n\t\t\t\t' + file_ref_id + ' /* PDFGenerator.swift */,',
    content
)

# Add to Sources build phase (after DidYouKnowFacts in Sources)
content = re.sub(
    r'(FC7EE2C05800D019614BC792 /\* DidYouKnowFacts.swift in Sources \*/,)',
    r'\1\n\t\t\t\t' + build_file_id + ' /* PDFGenerator.swift in Sources */,',
    content
)

# Write back
with open('Braindumpster.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"✅ Successfully added PDFGenerator.swift to Xcode project")
print(f"   File Ref ID: {file_ref_id}")
print(f"   Build File ID: {build_file_id}")

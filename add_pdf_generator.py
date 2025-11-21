#!/usr/bin/env python3
import uuid
import re

# Read the pbxproj file
with open('Braindumpster.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate unique IDs for the file references
file_ref_id = str(uuid.uuid4()).replace('-', '')[:24].upper()
build_file_id = str(uuid.uuid4()).replace('-', '')[:24].upper()

# Add file reference (find the last file reference in Utilities group)
file_ref_pattern = r'(/\* Utilities \*/.*?children = \()(.*?)(\);)'
match = re.search(file_ref_pattern, content, re.DOTALL)
if match:
    utilities_children = match.group(2)
    # Add PDFGenerator.swift reference
    new_ref = f'\n\t\t\t\t{file_ref_id} /* PDFGenerator.swift */,'
    new_children = utilities_children + new_ref
    content = content.replace(match.group(0), match.group(1) + new_children + match.group(3))

# Add PBXFileReference section
file_ref_section = f'''		{file_ref_id} /* PDFGenerator.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PDFGenerator.swift; sourceTree = "<group>"; }};
'''

# Find the PBXFileReference section and add our entry
pbx_file_ref_pattern = r'(/\* Begin PBXFileReference section \*/)'
content = re.sub(pbx_file_ref_pattern, r'\1\n' + file_ref_section, content)

# Add PBXBuildFile section
build_file_section = f'''		{build_file_id} /* PDFGenerator.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* PDFGenerator.swift */; }};
'''

# Find the PBXBuildFile section and add our entry
pbx_build_file_pattern = r'(/\* Begin PBXBuildFile section \*/)'
content = re.sub(pbx_build_file_pattern, r'\1\n' + build_file_section, content)

# Add to Sources build phase
sources_pattern = r'(/\* Sources \*/.*?files = \()(.*?)(\);)'
match = re.search(sources_pattern, content, re.DOTALL)
if match:
    sources_files = match.group(2)
    new_source = f'\n\t\t\t\t{build_file_id} /* PDFGenerator.swift in Sources */,'
    new_sources = sources_files + new_source
    content = content.replace(match.group(0), match.group(1) + new_sources + match.group(3))

# Write back
with open('Braindumpster.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"✅ Added PDFGenerator.swift to Xcode project")
print(f"   File Ref ID: {file_ref_id}")
print(f"   Build File ID: {build_file_id}")

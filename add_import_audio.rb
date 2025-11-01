#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Braindumpster.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Braindumpster' }

# Get or create the Views group
views_group = project.main_group['Views'] || project.main_group.new_group('Views')

# Get or create the MeetingRecorder group
meeting_recorder_group = views_group['MeetingRecorder'] || views_group.new_group('MeetingRecorder')

# File to add
file_path = 'Views/MeetingRecorder/ImportAudioView.swift'
file_name = File.basename(file_path)

# Check if file already exists in project
existing_file = meeting_recorder_group.files.find { |f| f.path == file_name }

unless existing_file
  # Add file reference
  file_ref = meeting_recorder_group.new_file(file_path)

  # Add to build phase
  target.add_file_references([file_ref])

  puts "Added #{file_name}"
else
  puts "#{file_name} already exists"
end

# Save the project
project.save

puts "Done!"

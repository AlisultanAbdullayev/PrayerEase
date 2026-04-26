require 'xcodeproj'
project = Xcodeproj::Project.open('PrayerEase.xcodeproj')
app_target = project.targets.find { |t| t.name == 'PrayerEase' }
app_target.dependencies.delete_if { |dep| dep.target.name == 'PrayerEaseWatch Watch App' }
app_target.copy_files_build_phases.each do |phase|
  if phase.name == 'Embed Watch Content'
    phase.clear
  end
end
project.save

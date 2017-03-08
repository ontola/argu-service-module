#!/usr/bin/ruby
# frozen_string_literal: true

def self.symlink?(file_name)
  return false if file_name == '.'
  return true if File.symlink?(file_name)
  symlink?(File.dirname(file_name))
end

wrong = []
missing = []
overwritten = []
Dir.glob('service_module/**/*') do |file|
  next if File.directory?(file) || %w(check_symlinks Gemfile service_module_internal).any? { |w| file.include?(w) }
  path = file.sub('service_module/', '')
  if !File.exist?(path)
    missing << path
  elsif !symlink?(path)
    overwritten << path
  elsif File.symlink?(path) && File.readlink(path) != "#{'../' * (file.count('/') - 1)}service_module/#{path}"
    wrong << path
  end
end

unless wrong.empty?
  puts 'Wrong symlinks:'
  wrong.each { |file_name| puts "* #{file_name} => #{File.readlink(file_name)}" }
  puts ''
end

unless missing.empty?
  puts 'Missing files:'
  missing.each { |file_name| puts "* #{file_name}" }
  puts ''
end

unless overwritten.empty?
  puts 'Overwritten files:'
  overwritten.each { |file_name| puts "* #{file_name}" }
  puts ''
end

puts "Wrong: #{wrong.count}"
puts "Missing: #{missing.count}"
puts "Overwritten: #{overwritten.count}"

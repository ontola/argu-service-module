# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc 'Loads the seed data from the filename provided in the first argument'
    task :single, [:seed_file] => [:environment] do |_t, args|
      filename = Dir[Rails.root.join('db', 'seeds', "#{args[:seed_file]}.seeds.rb")][0]
      puts "Seeding #{filename}..."
      load(filename) if File.exist?(filename)
    end
  end
end

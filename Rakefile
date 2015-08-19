require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new

task :default => :spec
task :test    => :spec
Rake::Task[:test].prerequisites << :compile

task :console do
  exec "irb -r harmonizer_redis -I ./lib"
end

Rake::ExtensionTask.new('white_similarity') do |extension|
  extension.lib_dir = 'lib/harmonizer_redis'
end

task :build => [:clean, :compile]
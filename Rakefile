require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

require "rake"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.libs.push "spec"
end

task default: :test

task :console do
  exec "irb -r ups -I ./lib"
end

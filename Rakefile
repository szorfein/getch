# frozen_string_literal: true

# https://github.com/seattlerb/minitest#running-your-tests-
require 'rake/testtask'
require File.dirname(__FILE__) + '/lib/getch/version'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_*.rb']
end

# Usage: rake gem:build
namespace :gem do
  desc 'build the gem'
  task :build do
    Dir['getch*.gem'].each {|f| File.unlink(f) }
    system('gem build getch.gemspec')
    system("gem install --user-install getch-#{Getch::VERSION}.gem -P HighSecurity")
  end
end

task :default => :test

# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

require 'tasks/docker'
require 'tasks/vagrant'

GEMSPEC = eval(File.read('ruby-production-breakpoints.gemspec'))
# ==========================================================
# Packaging
# ==========================================================

require 'rubygems/package_task'
Gem::PackageTask.new(GEMSPEC) do |_pkg|
end

namespace :new do
  desc 'Scaffold a new integration test'
  task :integration_test, [:test] do |_t, args|
    test_name = args[:test]
    integration_test_directory = 'test/integration'

    Dir.chdir(integration_test_directory) do
      test_folder = "test_#{test_name}"
      FileUtils.mkdir("test_#{test_name}")

      Dir.chdir(test_folder) do
        File.open("#{test_folder}.rb", 'w') do |file|
          file.write(test_scaffold(test_name))
        end
        FileUtils.touch("#{test_name}.bt")
        FileUtils.touch("#{test_name}.out")
        File.open("#{test_name}.rb", 'w') do |file|
          file.write(basic_script)
        end
      end
    end
  end

  def test_scaffold(test_name)
    <<~TEST
      require 'integration_helper'
       class #{test_name.capitalize}Test < IntegrationTestCase
        def test_#{test_name}
        end
      end
    TEST
  end

  def basic_script
    <<~SCRIPT
      require 'ruby-static-tracing'
      STDOUT.sync = true

    SCRIPT
  end
end

Rake::TestTask.new do |t|
  t.name = 'integration'
  t.libs << 'test/integration'
  t.test_files = FileList['test/integration/**/*_test.rb']
  t.verbose = true
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude(/integration/,
                                                       /tracer/)
  t.verbose = true
end

RuboCop::RakeTask.new

# ==========================================================
# Documentation
# ==========================================================
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task default: %w[rubocop test]

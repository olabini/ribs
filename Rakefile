require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :default => [:spec]
task :test => [:spec]

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.spec_files = FileList['test/**/*_spec.rb']
  t.verbose = true
  t.spec_opts = ["-fs", "--color"]
end

desc 'Generate RDoc'
Rake::RDocTask.new do |task|
  task.main = 'README'
  task.title = 'xample'
  task.rdoc_dir = 'doc'
  task.options << "--line-numbers" << "--inline-source"
  task.rdoc_files.include('README', 'lib/**/*.rb')
end

Gem::manage_gems

specification = Gem::Specification.new do |s|
  s.name   = "ribs"
  s.summary = "Ribs wraps Hibernate, to provide a good ORM for JRuby"
  s.version = "0.0.1"
  s.author = 'Ola Bini'
  s.description = s.summary
  s.homepage = 'http://ribs.rubyforge.org'
  s.rubyforge_project = 'ribs'

  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--title' << 'xample' << '--main' << 'README' << '--line-numbers'

  s.email = 'ola.bini@gmail.com'
  s.files = FileList['{lib,test}/**/*.rb', '[A-Z]*$', 'Rakefile'].to_a
#  s.add_dependency('mocha', '>= 0.5.5')
end

Rake::GemPackageTask.new(specification) do |package|
  package.need_zip = false
  package.need_tar = false
end

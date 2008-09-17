require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :ant do 
  ret = system('ant')
  if !ret
    raise "Compilation error"
  end
end

task :default => [:spec]
task :test => [:spec]

desc "Flog all Ruby files in lib"
task :flog do 
  system("find lib -name '*.rb' | xargs flog")
end

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.spec_files = FileList['test/**/*_spec.rb']
  t.verbose = true
  t.spec_opts = ["-fs", "--color"]
end

task :spec => [:ant]

desc 'Generate RDoc'
Rake::RDocTask.new do |task|
  task.main = 'README'
  task.title = 'ribs'
  task.rdoc_dir = 'doc'
  task.options << "--line-numbers" << "--inline-source"
  task.rdoc_files.include('README', 'lib/**/*.rb')
end

Gem::manage_gems

specification = Gem::Specification.new do |s|
  s.name   = "ribs"
  s.summary = "Ribs wraps Hibernate, to provide a good ORM for JRuby"
  s.version = "0.0.2"
  s.author = 'Ola Bini'
  s.description = s.summary
  s.homepage = 'http://ribs.rubyforge.org'
  s.rubyforge_project = 'ribs'

  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--title' << 'ribs' << '--main' << 'README' << '--line-numbers'

  s.email = 'ola.bini@gmail.com'
  s.files = FileList['{lib,test}/**/*.{rb,jar}', '[A-Z]*$', 'Rakefile'].to_a
#  s.add_dependency('mocha', '>= 0.5.5')
end

Rake::GemPackageTask.new(specification) do |package|
  package.need_zip = false
  package.need_tar = false
end

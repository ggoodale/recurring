# -*- ruby -*-

require 'rubygems'
require './lib/recurring'
require 'spec/rake/spectask'
require 'rake/gempackagetask'
require 'rake/rdoctask'

Spec::Rake::SpecTask.new :spec do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << "-f s"
end

task :default => :spec

specification = Gem::Specification.new do |s|
  s.name = %q{recurring}
  s.version = Recurring::VERSION
  s.platform = Gem::Platform::RUBY
  s.date = %q{2006-12-11}
  s.summary = %q{A scheduling library for recurring events}
  s.email = %q{jchris@mfdz.com}
  s.homepage = %q{http://jchris.mfdz.com}
  s.description = %q{Recurring allows you to define Schedules, which can tell you whether or not a given Time falls in the Schedule, as well as being able to return a list of times which match the Schedule within a given range.}
  s.authors = ["Chris Anderson"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/recurring.rb", "spec/date_language_spec.rb", "spec/schedule_spec.rb"]
  s.add_development_dependency(%q<rspec>, [">= 0.7.4"])
  s.has_rdoc = true
end

Rake::GemPackageTask.new specification do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new(:docs) do |rd|
  rd.main = "README.txt"
  rd.options << '-d' if RUBY_PLATFORM !~ /win32/ and `which dot` =~ /\/dot/
  rd.rdoc_dir = 'doc'
  files = ["History.txt", "README.txt", "Rakefile", "lib/date_language.rb", "lib/recurring.rb", "lib/schedule.rb", "spec/date_language_spec.rb", "spec/schedule_spec.rb"]
  rd.rdoc_files.push(*files)
  title = "Recurring Documentation"
  rd.options << "-t #{title}"
end

desc "Generate a gemspec file"
task :gemspec do
  File.open("#{specification.name}.gemspec", 'w') do |f|
    f.write specification.to_ruby
  end
end



# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{recurring}
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Anderson", "Grant Goodale"]
  s.autorequire = %q{recurring}
  s.date = %q{2006-12-11}
  s.description = %q{Recurring allows you to define Schedules, which can tell you whether or not a given Time falls in the Schedule, as well as being able to return a list of times which match the Schedule within a given range.}
  s.email = %q{jchris@mfdz.com}
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/recurring.rb", "spec/recurring_spec.rb"]
  s.homepage = %q{http://jchris.mfdz.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{A scheduling library for recurring events}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0.7.4"])
    else
      s.add_dependency(%q<rspec>, [">= 0.7.4"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0.7.4"])
  end
end

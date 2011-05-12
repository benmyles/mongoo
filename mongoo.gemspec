# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mongoo}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Myles"]
  s.date = %q{2011-05-11}
  s.description = %q{Simple object mapper for MongoDB}
  s.email = %q{ben.myles@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rvmrc",
    "CHANGELOG",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/mongoo.rb",
    "lib/mongoo/async.rb",
    "lib/mongoo/attribute_proxy.rb",
    "lib/mongoo/attribute_sanitizer.rb",
    "lib/mongoo/base.rb",
    "lib/mongoo/changelog.rb",
    "lib/mongoo/cursor.rb",
    "lib/mongoo/hash_ext.rb",
    "lib/mongoo/identity_map.rb",
    "lib/mongoo/modifiers.rb",
    "lib/mongoo/mongohash.rb",
    "lib/mongoo/persistence.rb",
    "mongoo.gemspec",
    "test/helper.rb",
    "test/test_activemodel.rb",
    "test/test_async.rb",
    "test/test_identity_map.rb",
    "test/test_mongohash.rb",
    "test/test_mongoo.rb"
  ]
  s.homepage = %q{http://github.com/benmyles/mongoo}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Object mapper for MongoDB}
  s.test_files = [
    "test/helper.rb",
    "test/test_activemodel.rb",
    "test/test_async.rb",
    "test/test_identity_map.rb",
    "test/test_mongohash.rb",
    "test/test_mongoo.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<i18n>, [">= 0.4.1"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.3"])
      s.add_runtime_dependency(%q<activemodel>, [">= 3.0.3"])
      s.add_runtime_dependency(%q<mongo>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<em-synchrony>, [">= 0.2.0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<i18n>, [">= 0.4.1"])
      s.add_dependency(%q<activesupport>, [">= 3.0.3"])
      s.add_dependency(%q<activemodel>, [">= 3.0.3"])
      s.add_dependency(%q<mongo>, [">= 1.3.1"])
      s.add_dependency(%q<em-synchrony>, [">= 0.2.0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<i18n>, [">= 0.4.1"])
    s.add_dependency(%q<activesupport>, [">= 3.0.3"])
    s.add_dependency(%q<activemodel>, [">= 3.0.3"])
    s.add_dependency(%q<mongo>, [">= 1.3.1"])
    s.add_dependency(%q<em-synchrony>, [">= 0.2.0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end


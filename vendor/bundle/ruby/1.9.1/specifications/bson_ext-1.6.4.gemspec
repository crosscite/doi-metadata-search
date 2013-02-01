# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bson_ext"
  s.version = "1.6.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mike Dirolf", "Kyle Banker", "Tyler Brock", "Gary Murakami"]
  s.date = "2012-06-06"
  s.description = "C extensions to accelerate the Ruby BSON serialization. For more information about BSON, see http://bsonspec.org.  For information about MongoDB, see http://www.mongodb.org."
  s.email = "mongodb-dev@googlegroups.com"
  s.extensions = ["ext/cbson/extconf.rb"]
  s.files = ["ext/cbson/extconf.rb"]
  s.homepage = "http://www.mongodb.org"
  s.require_paths = ["ext"]
  s.rubygems_version = "1.8.23"
  s.summary = "C extensions for Ruby BSON."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bson>, ["~> 1.6.4"])
    else
      s.add_dependency(%q<bson>, ["~> 1.6.4"])
    end
  else
    s.add_dependency(%q<bson>, ["~> 1.6.4"])
  end
end

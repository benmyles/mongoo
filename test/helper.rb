require 'rubygems'
require 'bundler'
begin
  groups = [:default, :development]
  Bundler.setup(groups)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongoo'

Mongoo.conn = lambda { Mongo::Connection.new("localhost", 27017, :pool_size => 5, :timeout => 5) }
Mongoo.db   = "mongoo-test"

class SearchIndex < Mongoo::Base
  describe do |d|
    d.attribute "terms", :type => :array
    d.index "terms"
  end
end

class Contact < Mongoo::Base
  describe do |o|
    o.attribute "email", :type => :string
    o.index "email", :unique => true
  end
end

class Person < Mongoo::Base
  describe do |d|
    d.attribute "name", :type => :string
    d.attribute "visits", :type => :integer
    d.attribute "interests", :type => :array
    d.attribute "jobs.total", :type => :integer
    d.attribute "jobs.professional", :type => :array
    d.attribute "jobs.volunteer", :type => :array
    d.attribute "jobs.internships.high_school", :type => :array
    d.attribute "location.city", :type => :string
    d.attribute "location.demographics.crime_rate", :type => :symbol
    d.attribute "location.demographics.education_quality", :type => :symbol
    d.attribute "misc", :type => :hash
    d.index "name"
    d.index "location.city"
  end
end

class SpacePerson < Mongoo::Base
  collection_name "spacemen"
end

class TvShow < Mongoo::Base
  describe do |d|
    d.attribute "name", :type => :string
    d.attribute "cast.director", :type => :string
    d.attribute "cast.lead", :type => :string
    d.attribute "rating", :type => :float
    d.attribute "comments", :type => :array
    d.index "name"
    d.index "cast.director"
  end

  validates_presence_of "name"
  validates_presence_of "cast.director"
  validates_presence_of "rating"
end

class Test::Unit::TestCase
end
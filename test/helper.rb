require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongoo'

Mongoo.db = Mongo::Connection.new.db('mongoo-test')

class SearchIndex < Mongoo::Base
  attribute "terms", :type => :array
  index "terms"
end

class Person < Mongoo::Base
  attribute "name", :type => :string
  attribute "visits", :type => :integer
  attribute "interests", :type => :array
  attribute "jobs.total", :type => :integer
  attribute "jobs.professional", :type => :array
  attribute "jobs.volunteer", :type => :array
  attribute "jobs.internships.high_school", :type => :array
  attribute "location.city", :type => :string
  attribute "location.demographics.crime_rate", :type => :symbol
  attribute "location.demographics.education_quality", :type => :symbol
  attribute "misc", :type => :hash
  
  index "name"
  index "location.city"
end

class TvShow < Mongoo::Base
  attribute "name", :type => :string
  attribute "cast.director", :type => :string
  attribute "cast.lead", :type => :string
  attribute "rating", :type => :float
  attribute "comments", :type => :array
  
  index "name"
  
  validates_presence_of "name"
  validates_presence_of "cast.director"
  validates_presence_of "rating"
end

class Test::Unit::TestCase
end

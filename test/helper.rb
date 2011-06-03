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

class Person < Mongoo::Base
  RE_EMAIL = /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i

  validator(
    /^email$/,  lambda { |v| v =~ RE_EMAIL ? nil : "email is invalid" })

  input_transformer(
    /_ts$/,     lambda { |v| v.to_f })

  input_transformer(
    /^friend$/, lambda { |v| v.is_a?(Person) ? v["_id"] : v })

  output_transformer(
    /^friend$/, lambda { |v| Person.find_one(v) }, { cache: true })
end


class SearchIndex < Mongoo::Base
end

class SpacePerson < Mongoo::Base
end

class TvShow < Mongoo::Base
end

=begin
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

class SpacePerson < Mongoo::Base
  collection_name "spacemen"
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
=end

class Test::Unit::TestCase
end
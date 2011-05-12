if ENV["MONGOO_ASYNC"]

require 'helper'
require "mongoo/async"

Mongoo.conn_opts = ["localhost", 27017, :pool_size => 5, :timeout => 5]
Mongoo.db_name   = "mongoo-test"

class TestAsync < Test::Unit::TestCase

  def setup
    EM.synchrony do

      [Person, TvShow, SearchIndex].each do |obj|
        obj.drop
        obj.create_indexes
      end
      EventMachine.stop
    end
  end

  should "set and get attributes" do
    EM.synchrony do
      p = Person.new("name" => "Ben")
      assert_equal "Ben", p.g(:name)
      assert_equal "Ben", p.get(:name)
      assert_equal "Ben", p.get_attribute(:name)
      p.set("location.city", "San Francisco")
      assert_equal "San Francisco", p.get("location.city")
      p.sets({"location.demographics.crime_rate" => :high, "location.demographics.education_quality" => :low})
      assert_equal({"name"=>"Ben",
       "location.demographics.crime_rate"=>:high}, p.gets(%w(name location.demographics.crime_rate)))
      assert_raise(Mongoo::UnknownAttributeError) { p.set("idontexist", "foo") }
      assert_raise(Mongoo::UnknownAttributeError) { p.get("idontexist") }
      assert_raise(NoMethodError) { p.idontexist }
      assert_raise(NoMethodError) { p.idontexist = "val" }
      EventMachine.stop
    end
  end
end

end
require 'helper'

class TestIdentityMap < Test::Unit::TestCase

  def setup
    [Person, TvShow, SearchIndex].each do |obj|
      obj.drop
      obj.create_indexes
    end
  end

  should "set and get attributes" do
    p = Person.new("name" => "Ben")
    p.insert!

    p2 = Person.find_one(p.id)
    assert_equal p, p2
    assert_not_equal p.object_id, p2.object_id

    Mongoo::IdentityMap.on!

    p3 = Person.find_one(p.id)
    p4 = Person.find_one(p.id)
    assert_equal p3, p4
    assert_equal p3.object_id, p4.object_id

    p4.name = "Ben Myles"
    assert_equal "Ben Myles", p3.name
    p4.update!
    assert_equal "Ben Myles", p3.name

    Mongoo::IdentityMap.flush!

    p50 = Person.find_one(p4.id)

    p5 = Person.find_one(p4.id)
    assert_not_equal p4.object_id, p5.object_id
    assert_equal Person.find_one(p5.id).object_id, p5.object_id

    t = Thread.new do
      assert_not_equal Person.find_one(p5.id).object_id, p5.object_id
    end; t.join

    assert_equal "Ben Myles", p5.name
    Person.collection.update({"_id" => p5.id}, { "name" => "Captain Awesome" })
    assert_equal "Ben Myles", Person.find_one(p5.id).name
    p5.name = "should error"
    assert_raise(Mongoo::StaleUpdateError) { p5.update! }
    p5.reload
    p5.name = "will work now"
    p5.update!

    assert_equal "will work now", p5.name
    assert_equal "will work now", p50.name

    Mongoo::IdentityMap.off!
  end

end
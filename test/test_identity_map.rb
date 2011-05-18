require 'helper'

class TestIdentityMap < Test::Unit::TestCase

  def setup
    [Person, TvShow, SearchIndex].each do |obj|
      obj.drop
      obj.create_indexes
    end
  end
  
  should "be performant" do
    1.upto(1000) do |i|
      p = Person.new("name" => "Ben#{i}")
      p.insert!
    end
    
    Mongoo::IdentityMap.on!
    
    all = Person.find.to_a
    
    p = Person.find(name: "Ben5").next
    assert_equal p.object_id, all[all.index(p)].object_id
    
    Mongoo::IdentityMap.off!
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

  should "use id map for simple queries only" do
    Mongoo::IdentityMap.on!

    p = Person.new("name" => "Ben")
    p.insert!
    p.name = "Not Ben"

    assert_equal "Not Ben", Person.find_one(p.id).name
    assert_equal "Not Ben", Person.find_one({"_id" => p.id}).name
    assert_equal "Not Ben", Person.find_one({:_id => p.id}).name

    assert_equal "Ben", Person.find_one(p.id, {sort: [["_id",-1]]}).name
    assert_equal "Ben", Person.find({"_id" => p.id}).next.name

    Mongoo::IdentityMap.off!
  end

  should "store results from find.to_a in map" do
    p = Person.new("name" => "Ben")
    p.insert!
    Mongoo::IdentityMap.on!

    people = Person.find.to_a
    people[0].name = "Not Ben"

    assert_equal "Not Ben", Person.find_one(p.id).name

    Mongoo::IdentityMap.off!
  end

  should "store results from find.each in map" do
    p = Person.new("name" => "Ben")
    p.insert!
    Mongoo::IdentityMap.on!

    people = []
    Person.find.each { |p| people << p }
    people[0].name = "Not Ben"

    assert_equal "Not Ben", Person.find_one(p.id).name

    Mongoo::IdentityMap.off!
  end

  should "store results from find.next in map" do
    p = Person.new("name" => "Ben")
    p.insert!
    Mongoo::IdentityMap.on!

    people = []
    people << Person.find.next

    people[0].name = "Not Ben"

    assert_equal "Not Ben", Person.find_one(p.id).name

    Mongoo::IdentityMap.off!
  end
end
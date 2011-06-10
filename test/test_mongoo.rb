require 'helper'

class TestMongoo < Test::Unit::TestCase

  def setup
    [Person, TvShow, SearchIndex].each do |obj|
      obj.drop
      obj.create_indexes
    end
  end

  should "respond to the correct attributes" do
    assert Person.new.respond_to?("jobs")
    assert !Person.new.respond_to?("cast")

    assert !TvShow.new.respond_to?("jobs")
    assert TvShow.new.respond_to?("cast")
  end

  should "have the right index meta" do
    assert Person.index_meta["location.city"]
    assert !Person.index_meta["cast.director"]

    assert !TvShow.index_meta["location.city"]
    assert TvShow.index_meta["cast.director"]
  end

  should "be able to use a different db for each model" do
    assert_equal "mongoo-test", Mongoo.db.name
    assert_equal "mongoo-test", Person.db.name

    Person.new(name: "mongoo-test").insert!
    assert_equal 1, Person.count
    assert_equal "mongoo-test", Person.find.next.name

    Person.db = "mongoo-test-people"
    assert_equal "mongoo-test-people", Person.db.name

    assert_equal 0, Person.count
    assert_equal 1, Mongoo.db.collection("people").count

    Person.new(name: "mongoo-test-people").insert!
    assert_equal 1, Person.count
    assert_equal "mongoo-test-people", Person.find.next.name

    Person.collection.drop
    Person.db = nil
    Person.conn = nil

    assert_equal 1, Person.count
    assert_equal "mongoo-test", Person.find.next.name
  end

  should "be able to use a different connection for each model" do
    assert_equal Person.conn.object_id, Mongoo.conn.object_id
    assert_equal Person.collection.db.connection.object_id, Mongoo.conn.object_id
    Person.conn = lambda { Mongo::Connection.new("localhost", 27017, :pool_size => 5, :timeout => 5) }
    assert_not_equal Person.conn.object_id, Mongoo.conn.object_id

    assert_not_equal Person.collection.db.connection.object_id, Mongoo.conn.object_id

    assert_equal Person.collection.db.connection.object_id, Person.conn.object_id
    Person.conn = nil
    assert_equal Person.conn.object_id, Mongoo.conn.object_id
    assert_equal Person.collection.db.connection.object_id, Mongoo.conn.object_id
  end

  should "set and get attributes" do
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
  end

  should "have attribute methods" do
    p = Person.new("name" => "Ben", "jobs" => { "professional" => "iList" })
    p.jobs.internships.high_school = ["Sun Microsystems"]
    assert_equal ["Sun Microsystems"], p.jobs.internships.high_school
    assert_equal ["Sun Microsystems"], p.get("jobs.internships.high_school")
    p.name = "Ben Myles"
    assert_equal "Ben Myles", p.name
    assert_equal "Ben Myles", p.get("name")
  end

  should "never has the same object for persisted_mongohash and mongohash" do
    p = Person.new("name" => "Ben")
    p.insert
    p.name = "Ben Myles"
    assert_not_equal p.persisted_mongohash.raw_hash, p.mongohash.raw_hash
    p.update
    assert_equal p.persisted_mongohash.raw_hash, p.mongohash.raw_hash
    p.name = "Ben 2"
    assert_not_equal p.persisted_mongohash.raw_hash, p.mongohash.raw_hash
  end

  should "be able to do crud" do
    p = Person.new("name" => "Ben")
    p.jobs.internships.high_school = ["Sun Microsystems"]
    p.insert

    p = Person.find_one(p.id)
    p.update
    p.location.city = "San Francisco"
    p.update
    p.name = "Ben Myles"
    p.location.city = "San Diego"
    assert_not_equal p.persisted_mongohash.raw_hash, p.mongohash.raw_hash
    p.update

    p2 = Person.find_one(p.id)
    assert_equal "Ben Myles", p2.name
    assert_equal "San Diego", p2.location.city

    p.location.city = "Los Angeles"
    p.update!

    p2.location.city = "San Jose"
    assert_raise(Mongoo::StaleUpdateError) { p2.update! }
    p2.location.city = "San Diego"
    p2.name = "Benjamin"
    p2.update!

    assert p2.reload

    assert_equal "Los Angeles", p2.location.city
    assert_equal "Benjamin", p2.name

    assert p2.persisted_mongohash.raw_hash["location"].has_key?("city")
    p2.unset "location.city"
    p2.update
    assert !p2.persisted_mongohash.raw_hash["location"].has_key?("city")

    p2.location.demographics.crime_rate = :high
    p2.location.city = "San Bruno"
    p2.update
    assert_raise(NoMethodError) { p2.location.demographics = 123 }

    p2.unset "location"
    p2.update
    p2 = Person.find_one(p2.id)
    assert !p2.persisted_mongohash.raw_hash.has_key?("location")

    p2.location.city = "Brisbane"
    p2.location.demographics.crime_rate = :low
    p2.update
    assert_equal ["Brisbane", :low], [p2.location.city, p2.location.demographics.crime_rate]
    p2 = Person.find_one(p2.id)
    assert_equal ["Brisbane", :low], [p2.location.city, p2.location.demographics.crime_rate]
    p2.location.unset
    p2.update
    assert !p2.persisted_mongohash.raw_hash.has_key?("location")
    p2 = Person.find_one(p2.id)
    assert !p2.persisted_mongohash.raw_hash.has_key?("location")

    p2.location.city = "Brisbane"
    p2.location.demographics.crime_rate = :low
    p2.update
    assert_equal ["Brisbane", :low], [p2.location.city, p2.location.demographics.crime_rate]
    assert p2.persisted_mongohash.raw_hash["location"].has_key?("demographics")
    p2.location.demographics.unset
    p2.update
    assert !p2.persisted_mongohash.raw_hash["location"].has_key?("demographics")
    p2 = Person.find_one(p2.id)
    assert !p2.persisted_mongohash.raw_hash["location"].has_key?("demographics")
    assert_equal "Brisbane", p2.location.city
  end

  should "be able to modify fields" do
    p = Person.new("name" => "Ben", "visits" => 0)
    p.insert!
    assert_equal 0, p.visits

    p.mod! do |mod|
      mod.inc "visits", 2
      mod.set "jobs.total", 10
    end
    assert_equal 2, p.visits
    assert_equal 10, p.jobs.total
    assert_equal [], p.changelog
    p = Person.find_one(p.id)
    assert_equal 2, p.visits
    assert_equal 10, p.jobs.total

    p.jobs.mod! do |mod|
      mod.inc "total", 5
    end
    assert_equal 15, p.jobs.total
    p = Person.find_one(p.id)
    assert_equal 15, p.jobs.total

    assert_equal nil, p.interests
    p.mod! { |mod| mod.push("interests", "skydiving") }
    assert_equal ["skydiving"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving"], p.interests
    p.mod! { |mod| mod.push("interests", "snowboarding") }
    assert_equal ["skydiving", "snowboarding"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving", "snowboarding"], p.interests

    p.mod! { |mod| mod.push_all("interests", ["reading","travelling"]) }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests

    p.mod! { |mod| mod.add_to_set("interests", "skydiving") }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests
    p.mod! { |mod| mod.add_to_set("interests", "swimming") }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling", "swimming"], p.interests
    p.mod! { |mod| mod.add_to_set("interests", "swimming") }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling", "swimming"], p.interests

    p.mod! { |mod| mod.pop("interests") }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests

    p.mod! { |mod| mod.pop("interests") }
    assert_equal ["skydiving", "snowboarding", "reading"], p.interests

    p.mod! { |mod| mod.push("interests", "reading") }
    assert_equal ["skydiving", "snowboarding", "reading", "reading"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving", "snowboarding", "reading", "reading"], p.interests
    p.mod! { |mod| mod.pull("interests", "reading") }
    assert_equal ["skydiving", "snowboarding"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving", "snowboarding"], p.interests

    p.mod! { |mod| mod.push_all("interests", ["reading","travelling"]) }
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["skydiving", "snowboarding", "reading", "travelling"], p.interests

    p.mod! { |mod| mod.pull_all("interests", ["reading", "skydiving"]) }
    assert_equal ["snowboarding", "travelling"], p.interests
    p = Person.find_one(p.id)
    assert_equal ["snowboarding", "travelling"], p.interests
  end

  should "be able to access a hash type directly" do
    p = Person.new("name" => "Ben")
    p.insert!
    assert_equal nil, p.misc
    p.misc = { "height" => 5.5, "weight" => 160 }
    p.update!
    assert_equal({ "height" => 5.5, "weight" => 160 }, p.misc)
    p.update!
    p = Person.find_one(p.id)
    assert_equal({ "height" => 5.5, "weight" => 160 }, p.misc)
    p.misc["height"] = 5.6
    p.misc["eyes"] = :blue
    assert_equal({ "height" => 5.6, "weight" => 160, "eyes" => :blue }, p.misc)
    p.update!
    assert_equal({ "height" => 5.6, "weight" => 160, "eyes" => :blue }, p.misc)
    p = Person.find_one(p.id)
    assert_equal({ "height" => 5.6, "weight" => 160, "eyes" => :blue }, p.misc)
  end

  should "cast to type automatically" do
    p = Person.new("name" => "ben")
    p.insert!
    p.visits = "5"
    assert_equal 5, p.visits
    p.update!
    p = Person.find_one(p.id)
    assert_equal 5, p.visits
    p.mod! { |mod| mod.inc("visits", 3) }
    assert_equal 8, p.visits
    p = Person.find_one(p.id)
    assert_equal 8, p.visits
  end

  should "validate documents" do
    show = TvShow.new
    assert !show.valid?
    assert !show.insert
    assert_equal({:name=>["can't be blank"],
     :"cast.director"=>["can't be blank"],
     :rating=>["can't be blank"]}, show.errors)
    show.cast.director = "Some Guy"
    show.name = "Some Show"
    assert !show.valid?
    assert !show.insert
    assert_raise(Mongoo::NotValidError) { show.insert! }
    assert_equal({:rating=>["can't be blank"]}, show.errors)
    show.rating = 3.0
    assert show.valid?
    show.insert!
  end

  should "not care if keys are symbols or hashes" do
    p = Person.new(:name => "Ben")
    assert_equal "Ben", p.name
  end

  should "be able to merge properties into the mongohash" do
    p = Person.new("name" => "Ben", "visits" => 10, "location" => { "city" => "SF" })
    p.insert!
    p = Person.find_one(p.id)
    assert_equal "Ben", p.name
    assert_equal 10, p.visits
    assert_equal "SF", p.location.city
    p.merge!({"visits" => 12, "location" => { "demographics" => {"crime_rate" => :high} } })
    assert_equal "Ben", p.name
    assert_equal 12, p.visits
    assert_equal "SF", p.location.city
  end

  should "not fail on an empty array" do
    i = SearchIndex.new(:terms => [])
    i.insert!
    i.terms << "foo"
    i.update!
  end

  should "work when forked" do
    Person.new(:name => "Ben").insert!
    fork { assert_equal "Ben", Person.find_one({name: "Ben"}).name }
    Process.wait
  end

  should "work when threaded" do
    1.upto(10) do |i|
      Person.new(:name => "Ben#{i}").insert!
    end

    threads = []
    100.times do |count|
      threads << Thread.new do
        (1..10).to_a.shuffle { |i| assert_equal "Ben#{i}", Person.find_one({name: "Ben#{i}"}).name }
      end
    end
    threads.each { |th| th.join }
  end

  should "be able to set the collection name manually" do
    assert_equal "people", Person.collection.name
    assert_equal "spacemen", SpacePerson.collection.name
  end

  should "be able to use find_and_modify" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"])
    p.insert!
    p2 = Person.find_and_modify({
      query: { name: "Ben" },
      update: { "$push" => { "interests" => "swimming" } },
      new: true
    })
    assert_equal ["skydiving", "coding", "swimming"], p2.interests
    assert_equal ["skydiving", "coding"], p.interests
    p.reload
    assert_equal ["skydiving", "coding", "swimming"], p.interests
  end

  should "still do set/unset updates on granular attributes on a hash field" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"], misc: { foo: { bar: 1, zar: 2 } })
    p.insert!
    p.misc['foo']['zar'] = 3
    assert_equal [[:set, "misc.foo.zar", 3]], p.changelog
  end

  should "be able to apply modifiers on hash attribute values" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"], misc: { foo: { bar: 1, zar: 2 } })
    p.insert!
    p.mod { |m| m.inc 'misc.foo.zar', 2 }
    assert_equal 4, p.misc['foo']['zar']
    p.reload
    assert_equal 4, p.misc['foo']['zar']
  end

  should "be able to abort modifier update if there are stale values" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"], misc: { foo: { bar: 1, zar: 2 } })
    p.insert!
    p.mod { |m| m.inc 'misc.foo.zar', 2 }

    p2 = Person.find_one(p.id)
    p2.mod { |m| m.inc 'misc.foo.zar', 2 }
    assert_equal 6, p2.misc['foo']['zar']

    assert_raise(Mongoo::ModifierUpdateError) do
      p.mod(only_if_current: true) { |m| m.inc 'misc.foo.zar', 1 }
    end
  end

  should "be able to do a find_and_modify when using modifiers" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"], misc: { foo: { bar: 1, zar: 2 } })
    p.insert!
    p.mod { |m| m.inc 'misc.foo.zar', 2 }

    p2 = Person.find_one(p.id)
    p2.mod { |m| m.inc 'misc.foo.zar', 2 }
    assert_equal 6, p2.misc['foo']['zar']

    p.mod { |m| m.inc 'misc.foo.zar', 1 }
    assert_equal 5, p.misc['foo']['zar']

    # but if we do a find_and_modify ....

    p = Person.new(name: "Ben", interests: ["skydiving", "coding"], misc: { foo: { bar: 1, zar: 2 } })
    p.insert!
    p.mod { |m| m.inc 'misc.foo.zar', 2 }

    p2 = Person.find_one(p.id)
    p2.mod { |m| m.inc 'misc.foo.zar', 2 }
    assert_equal 6, p2.misc['foo']['zar']

    p.mod(find_and_modify: true) { |m| m.inc 'misc.foo.zar', 1 }
    assert_equal 7, p.misc['foo']['zar']
  end

  should "be able to do an update using find_and_modify" do
    p = Person.new(name: "Ben", interests: ["skydiving", "coding"])
    p.insert!

    p2 = Person.find_one(p.id)
    p2.mod! { |m| m.push "interests", "swimming" }

    assert_equal ["skydiving","coding"], p.interests
    p.name = "Ben Myles"
    p.update!(find_and_modify: true)
    assert_equal "Ben Myles", p.name
    assert_equal ["skydiving", "coding", "swimming"], p.interests
  end

  should "be just one _id key after insert" do
    p = Person.new(name: "Ben")
    p.insert!
    assert p.mongohash.has_key?('_id')
    assert !p.mongohash.has_key?(:_id)
    p.name = "Ben Myles"
    p.update!
    assert p.mongohash.has_key?('_id')
    assert !p.mongohash.has_key?(:_id)
    p = Person.find_one(p.id)
    assert p.mongohash.has_key?('_id')
    assert !p.mongohash.has_key?(:_id)
  end

  should "be able to use save! instead of insert/update" do
    p = Person.new(name: "Ben")
    assert !p.persisted?
    p.save!
    assert p.persisted?
    assert_equal "Ben", Person.find_one(p.id).name
    p.name = "Benjamin"
    p.save!
    assert p.persisted?
    assert_equal "Benjamin", Person.find_one(p.id).name
  end

  should "be able to use save instead of insert/update" do
    p = Person.new(name: "Ben")
    assert !p.persisted?
    p.save
    assert p.persisted?
    assert_equal "Ben", Person.find_one(p.id).name
    p.name = "Benjamin"
    p.save
    assert p.persisted?
    assert_equal "Benjamin", Person.find_one(p.id).name
  end

end


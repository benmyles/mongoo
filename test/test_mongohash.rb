require 'helper'

class TestMongohash < Test::Unit::TestCase
  should "work with dot_get, dot_set, dot_delete" do
    h = Mongoo::Mongohash.new({
      "name" => "Ben", 
      "travel" => {},
      "location" => { "city" => "SF", "zip" => 94107, "demographics" => { "pop" => 120000 } }})
    assert_equal "Ben", h.dot_get("name")
    assert_equal "SF", h.dot_get("location.city")
    assert_equal 94107, h.dot_get("location.zip")
    assert_equal 120000, h.dot_get("location.demographics.pop")
    assert_equal nil, h.dot_get("foobar")
    assert_equal nil, h.dot_get("location.idontexist.andneitherdoi")
    h.dot_set("location.demographics.pop", 10000)
    assert_equal 10000, h.dot_get("location.demographics.pop")
    h.dot_set("interests", ["skydiving"])
    assert_equal ["skydiving"], h.dot_get("interests")
    h.dot_set("languages.fluent", ["english"])
    h.dot_set("languages.nonfluent", ["german"])
    assert_equal ["english"], h.dot_get("languages.fluent")
    assert_equal ["german"], h.dot_get("languages.nonfluent")
    h.dot_delete("languages.fluent")
    assert_equal nil, h.dot_get("languages.fluent")
    h.dot_delete("languages")
    assert_equal nil, h.dot_get("languages")
    assert_equal "Ben", h.dot_get("name")
    h.dot_delete("name")
    assert_equal nil, h.dot_get("name")
  end
  
  should "not be able to initialize an object with undefined attributes" do
    assert_raise(Mongoo::UnknownAttributeError) { Person.new(:idontexist => "bah") }
  end
end

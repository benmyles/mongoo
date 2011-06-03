require "helper"

class TestDocument < Test::Unit::TestCase
  should "have an oplog" do
    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: Time.mktime(1984, 2, 2) })
    assert_equal({}, doc.oplog)
    doc["name"] = "Ben Myles"
    assert_equal({"$set" => { "name" => "Ben Myles"}}, doc.oplog)
    doc["dob"] = nil
    assert_equal({"$set" => { "name" => "Ben Myles", "dob" => nil}}, doc.oplog)
    doc.unset "dob"
    assert_equal({"$set" => { "name" => "Ben Myles" }, "$unset" => { "dob" => 1}}, doc.oplog)
  end

  should "have validators" do
    validators = []
    validators << Mongoo::Document::Validator.new(/^dob$/,
                    lambda { |val| val.is_a?(Time) ? nil : ["must be a time"] })

    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: Time.mktime(1984, 2, 2) },
                               { validators: validators })
    assert_equal({}, doc.errors)
    doc["dob"] = 1234
    assert_equal({ "dob" => ["must be a time"] }, doc.errors)
    doc["dob"] = Time.mktime(1984, 2, 2)
    assert_equal({}, doc.errors)
  end

  should "have transformers" do
    transformers = []
    transformers << Mongoo::Document::Transformer.new(/^dob$/, lambda { |val| val.to_i })
    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: Time.mktime(1984, 2, 2) },
                               { input_transformers: transformers })
    assert_equal 444556800, doc["dob"]
  end

  should "run transformers before validators" do
    validators = []
    validators << Mongoo::Document::Validator.new(/^dob$/,
                    [ lambda { |val| val.is_a?(Fixnum) ? nil : ["must be a Fixnum"] },
                      lambda { |val| val > 0 ? nil : ["must be > 0"] } ])

    transformers = []
    transformers << Mongoo::Document::Transformer.new(/^dob$/, lambda { |val| val.to_i })

    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: Time.mktime(1984, 2, 2) },
                               { validators: validators, input_transformers: transformers })

    assert doc.errors.blank?
    assert_equal 444556800, doc["dob"]

    doc["dob"] = "a"
    assert_equal 0, doc["dob"]
    assert_equal({ "dob" => ["must be > 0"] }, doc.errors)
  end

  should "run validation lambdas in order and break on error" do
    validators = []
    validators << Mongoo::Document::Validator.new(/^dob$/,
                    [ lambda { |val| val.is_a?(Fixnum) ? nil : ["must be a Fixnum"] },
                      lambda { |val| val > 0 ? nil : ["must be > 0"] } ])

    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: "a" },
                               { validators: validators })

    assert_equal "a", doc["dob"]
    assert_equal({ "dob" => ["must be a Fixnum"] }, doc.errors)
  end

  should "have output transformers" do
    in_transformers = []
    in_transformers << Mongoo::Document::Transformer.new(/^dob$/, lambda { |val| val.to_i })

    out_transformers = []
    out_transformers << Mongoo::Document::Transformer.new(/^dob$/, lambda { |val| val.nil? ? nil : Time.at(val) })

    doc = Mongoo::Document.new({ name: "Ben",
                                 interests: ["skydiving", "coding"],
                                 dob: Time.mktime(1984, 2, 2) },
                               { input_transformers:  in_transformers,
                                 output_transformers: out_transformers })

    assert doc.errors.blank?

    assert_equal Time.mktime(1984, 2, 2), doc["dob"]
    assert_equal 444556800, doc.map["dob"]
    assert_equal 444556800, doc.to_hash["dob"]
  end
end



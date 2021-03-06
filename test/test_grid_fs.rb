require 'helper'

class Email < Mongoo::Base
  include Mongoo::GridFs

  describe do |d|
    d.attribute "subject", :type => :string
    d.embeds_one "attachment", :class => "Email::Attachment"
    d.grid_fs_file  "raw_message"
    d.grid_fs_files "notes"
  end
end

class Email::Attachment < Mongoo::Embedded::Base
  include Mongoo::GridFs

  describe do |d|
    d.attribute "filename", :type => :string
    d.grid_fs_file "data"
  end
end

class Image < Mongoo::Base
  include Mongoo::GridFs
end

class TestGridFs < Test::Unit::TestCase

  def setup
    [Email].each do |obj|
      obj.drop
      obj.create_indexes
    end
  end

  should "be able to use a file in a normal doc" do
    e = Email.new(subject: "Hello, World!")
    assert_equal Mongoo::GridFs::File, e.raw_message.class
    assert_nil e.raw_message.get
    assert_nil e.raw_message.delete
    file_id = e.raw_message.put "Welcome to GridFS!"
    assert file_id.is_a?(BSON::ObjectId)
    assert_equal "Welcome to GridFS!", e.raw_message.get
    e.insert!
    assert_equal "Welcome to GridFS!", e.raw_message.get

    e = Email.find_one(e.id)
    assert_equal "Welcome to GridFS!", e.raw_message.get
    e.raw_message.delete
    assert_nil e.raw_message.get
    e.update!

    e = Email.find_one(e.id)
    assert_nil e.raw_message.get
  end

  should "be able to use a file in an embedded doc" do
    e = Email.new(subject: "Hello, World!")
    e.attachment = Email::Attachment.new(e, {filename: "secret.txt"})
    assert_nil e.attachment.data.get
    e.attachment.data.put "super secret message"
    assert_equal "super secret message", e.attachment.data.get
    e.attachment.save!

    e = Email.find_one(e.id)
    assert_equal "super secret message", e.attachment.data.get
    e.attachment.data.delete
    assert_nil e.attachment.data.get
    e.save!

    e = Email.find_one(e.id)
    assert_nil e.attachment.data.get
  end

  should "be able to have multiple files keyed under a hash" do
    e = Email.new(subject: "Hello, World!")
    assert_equal Mongoo::GridFs::Files, e.notes.class
    assert_nil e.notes.get("monday")
    e.notes.put("tuesday", "Tuesday is a good day.")
    assert_equal "Tuesday is a good day.", e.notes.get("tuesday")
    e.insert!
    e = Email.find_one(e.id)
    assert_equal "Tuesday is a good day.", e.notes.get("tuesday")
    e.notes.delete("tuesday")
    assert_nil e.notes.get("tuesday")
    e.update!
    e = Email.find_one(e.id)
    assert_nil e.notes.get("tuesday")
  end

end
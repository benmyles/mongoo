require 'helper'

class Book < Mongoo::Base
  attribute "title",          :type => :string

  attribute "chapters",       :type => :hash
  attribute "authors",        :type => :hash
  attribute "sample_chapter", :type => :hash
  attribute "purchases",      :type => :hash

  embeds_one  "sample_chapter", :as => "sample_chapter",  :class => "Book::Chapter"
  embeds_many "chapters",       :as => "chapters",        :class => 'Book::Chapter'
  embeds_many "authors",        :as => "authors",         :class => 'Book::Author'
  embeds_many "purchases",      :as => "purchases",       :class => 'Book::Purchase'
end

class Book::Chapter < Mongoo::Embedded::Base
  attribute "title", :type => :string
end

class Book::Author < Mongoo::Embedded::Base
  attribute "first_name", :type => :string
  attribute "last_name",  :type => :string
end

class Book::Purchase < Mongoo::Embedded::Base
  attribute "payment_type",  :type => :string

  attribute   "customer", :type => :hash
  embeds_one  "customer", :as => "customer", :class => 'Book::Purchase::Customer'

  validates_presence_of :payment_type
end

class Book::Purchase::Customer < Mongoo::Embedded::Base
  attribute "name", :type => :string
  attribute "phone", :type => :string
  validates_presence_of :name
  validates_presence_of :phone
end

class TestEmbedded < Test::Unit::TestCase
  def setup
    Book.collection.drop
  end

  should "be able to work with embedded doc hashes" do
    b = Book.new
    b.authors["primary"]   = b.authors.build(first_name: "Ben", last_name: "Myles")
    b.authors["secondary"] = b.authors.build(first_name: "John", last_name: "Smith")

    assert_equal "Ben", b.authors["primary"].first_name
    assert_equal "Smith", b.authors["secondary"].last_name

    assert_equal 2, b.authors.size
    assert_equal ["primary", "secondary"], b.authors.keys

    b.insert!

    b = Book.find_one(b.id)

    assert_equal "Ben", b.authors["primary"].first_name
    assert_equal 2, b.authors.size
    assert_equal ["primary", "secondary"], b.authors.keys
  end

  should "be able to work with a single embedded doc" do
    b = Book.new(title: "BASE Jumping Basics")
    b.sample_chapter = Book::Chapter.new(b, {})
    b.sample_chapter.title = "Understanding the Risks"
    assert_equal "Understanding the Risks", b.g('sample_chapter')['title']
    b.insert!
    b = Book.find_one(b.id)
    assert_equal "Understanding the Risks", b.sample_chapter.title
    assert_equal "Understanding the Risks", b.g('sample_chapter')['title']
  end

  should "validate embedded docs and can have nested embeds" do
    b = Book.new(title: "BASE Jumping Basics")
    b.insert!

    purchase_id = BSON::ObjectId.new.to_s
    b.purchases[purchase_id] = b.purchases.build({})
    assert !b.valid?
    assert_equal({:"purchases.#{purchase_id}.payment_type"=>["can't be blank"]}, b.errors)
    b.purchases[purchase_id].payment_type = "Cash"
    assert b.valid?
    b.update!

    b = Book.find_one(b.id)
    assert_equal "Cash", b.purchases[purchase_id].payment_type
    assert_nil b.purchases[purchase_id].customer
    b.purchases[purchase_id].customer = Book::Purchase::Customer.new(b.purchases[purchase_id], name: "Jiminy")
    assert_equal "Jiminy", b.purchases[purchase_id].customer.name
    assert !b.valid?
    assert_equal({:"purchases.#{purchase_id}.customer.phone"=>["can't be blank"]}, b.errors)
    b.purchases[purchase_id].customer.phone = "123"
    assert b.valid?
    b.update!
    b = Book.find_one(b.id)
    assert_equal "Jiminy", b.purchases[purchase_id].customer.name
    b.purchases[purchase_id].customer = nil
    assert_equal [[:unset, "purchases.#{purchase_id}.customer", 1]], b.changelog
    b.update!
    b = Book.find_one(b.id)
    assert_nil b.purchases[purchase_id].customer
    assert_equal [], b.changelog
  end

  should "be able to delete a doc in an embeds_many" do
    b = Book.new(title: "BASE Jumping Basics")

    purchase_id = BSON::ObjectId.new.to_s
    b.purchases[purchase_id] = b.purchases.build({payment_type: "Cash"})

    purchase_id2 = BSON::ObjectId.new.to_s
    b.purchases[purchase_id2] = b.purchases.build({payment_type: "Card"})

    assert_equal 3, b.changelog.size
    b.purchases.delete(purchase_id2)
    assert_equal 2, b.changelog.size
    b.purchases[purchase_id2] = b.purchases.build({payment_type: "Card"})
    assert_equal 3, b.changelog.size

    b.insert!

    assert_equal 2, b.purchases.size

    b.purchases.delete(purchase_id2)
    assert_equal 1, b.purchases.size
    assert_equal 1, b.changelog.size
    b.update!
    assert_equal 1, b.purchases.size

    b = Book.find_one(b.id)
    assert_equal 1, b.purchases.size
  end

  should "be able to call save from an embedded doc" do
    b = Book.new(title: "BASE Jumping Basics")
    purchase_id = BSON::ObjectId.new.to_s
    b.purchases[purchase_id] = b.purchases.build({payment_type: "Cash"})
    b.purchases[purchase_id].save!

    b = Book.find_one(b.id)
    assert_equal "Cash", b.purchases[purchase_id].payment_type
    b.purchases[purchase_id].payment_type = "Card"
    b.purchases[purchase_id].save!
    b = Book.find_one(b.id)
    assert_equal "Card", b.purchases[purchase_id].payment_type
    b.purchases[purchase_id].payment_type = "Paypal"
    b.save!
    b = Book.find_one(b.id)
    assert_equal "Paypal", b.purchases[purchase_id].payment_type
  end
end
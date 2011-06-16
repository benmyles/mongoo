require 'helper'

class Customer < Mongoo::Base
  describe do |d|
    d.attribute "name", :type => :string
    d.embeds_many "addresses", :class => "Customer::Address", :type => :array
  end
end

class Customer::Address < Mongoo::Embedded::Base
  describe do |d|
    d.attribute "street", :type => :string
    d.attribute "city", :type => :string
  end
end

class Book < Mongoo::Base
  describe do |d|
    d.attribute "title", :type => :string
    d.embeds_one  "sample_chapter",  :class => "Book::Chapter"
    d.embeds_many "chapters",        :class => 'Book::Chapter'
    d.embeds_many "authors",         :class => 'Book::Author'
    d.embeds_many "purchases",       :class => 'Book::Purchase'
  end
end

class Book::Chapter < Mongoo::Embedded::Base
  describe do |d|
    d.attribute "title", :type => :string
  end
end

class Book::Author < Mongoo::Embedded::Base
  describe do |d|
    d.attribute "first_name", :type => :string
    d.attribute "last_name",  :type => :string
  end
end

class Book::Purchase < Mongoo::Embedded::Base
  describe do |d|
    d.attribute "payment_type",  :type => :string
    d.embeds_one "customer", :class => 'Book::Purchase::Customer'
  end

  validates_presence_of :payment_type
end

class Book::Purchase::Customer < Mongoo::Embedded::Base
  describe do |d|
    d.attribute "name", :type => :string
    d.attribute "phone", :type => :string
  end

  validates_presence_of :name
  validates_presence_of :phone
end

class TestEmbedded < Test::Unit::TestCase
  def setup
    Book.collection.drop
    Customer.collection.drop
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

  should "be able to get the key of the embedded doc" do
    b = Book.new(title: "BASE Jumping Basics")
    purchase_key = BSON::ObjectId.new.to_s
    b.purchases[purchase_key] = b.purchases.build({payment_type: "Cash"})
    assert_equal purchase_key, b.purchases[purchase_key].key
    b.purchases[purchase_key].save!

    b = Book.find_one(b.id)
    assert_equal purchase_key, b.purchases[purchase_key].key

    assert_equal purchase_key, b.purchases.first.key
    assert_equal purchase_key, b.purchases.last.key
    assert_equal [purchase_key], b.purchases.all.collect { |p| p.key }
  end

  should "be able to push an embedded doc if we want an auto gen key" do
    b = Book.new(title: "BASE Jumping Basics")
    doc = b.purchases.build({payment_type: "Cash"})
    key = b.purchases.push(doc)
    assert_nothing_raised { BSON::ObjectId(key) }
    assert_equal doc, b.purchases[key]
    b.insert!
    b = Book.find_one(b.id)
    assert_nothing_raised { BSON::ObjectId(key) }
    assert_equal doc, b.purchases[key]
  end

  should "be able to have an embedded array doc" do
    c = Customer.new(name: "Ben")
    assert c.addresses.empty?
    c.insert!

    address = c.addresses.build(street: "123 Street", city: "Metropolis")
    c.addresses << address
    assert_equal address, c.addresses.first
    assert_equal address, c.addresses[0]
    assert_equal 1, c.addresses.size

    c.update!
    assert_equal address, c.addresses.first
    assert_equal address, c.addresses[0]
    assert_equal 1, c.addresses.size
    c = Customer.find_one(c.id)
    assert_equal address, c.addresses.first
    assert_equal address, c.addresses[0]
    assert_equal 1, c.addresses.size

    market_st = c.addresses.build(street: "Market Street", city: "San Francisco")
    c.mod! do |m|
      m.push "addresses", market_st.to_hash
    end

    assert_equal 2, c.addresses.size
    assert_equal market_st, c.addresses.last
    c = Customer.find_one(c.id)
    assert_equal address, c.addresses.first
    assert_equal address, c.addresses[0]
    assert_equal 2, c.addresses.size
    assert_equal market_st, c.addresses[1]
    assert_equal market_st, c.addresses.last

    c.mod! do |m|
      m.pull 'addresses', market_st
    end

    assert_equal 1, c.addresses.size
    assert_equal [address], c.addresses.to_a
  end
end
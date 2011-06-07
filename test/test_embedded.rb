require 'helper'

class Book < Mongoo::Base
  attribute "title",    :type => :string
  attribute "chapters", :type => :array
  attribute "authors",  :type => :hash
  attribute "sample_chapter", :type => :hash

  def chapters
    @chapters ||= embedded_array_proxy(get_or_set('chapters',[]), Book::Chapter)
  end

  def authors
    @authors ||= embedded_hash_proxy(get_or_set('authors', {}), Book::Author)
  end

  def sample_chapter
    @sample_chapter ||= embedded_doc(get_or_set('sample_chapter', {}), Book::Chapter)
  end
end

class Book::Chapter < Mongoo::Embedded::Base
  attribute "title", :type => :string
end

class Book::Author < Mongoo::Embedded::Base
  attribute "first_name", :type => :string
  attribute "last_name",  :type => :string
end

class TestEmbedded < Test::Unit::TestCase
  def setup
    Book.collection.drop
  end

  should "be able to work with embedded doc arrays" do
    b = Book.new
    b.title = "Skydiving Instruction Manual"

    b.chapters.push(b.chapters.build(title: "How to Land"))

    b2 = Book.new(title: "Something Else")
    b2.chapters.push b2.chapters.build(title: "How to Transcend Fear")

    assert_equal [], b.chapters.raw & b2.chapters.raw

    b2.chapters.push b2.chapters.build({title: "How to Land"})

    assert_equal([{"title"=>"How to Land"}], b.chapters.raw & b2.chapters.raw)

    assert_equal b.chapters.range(0,0), b2.chapters.range(1,1)
    assert_not_equal b.chapters.range(0,0), b2.chapters.range(0,0)

    assert_equal 2, b2.chapters.size

    assert_equal "How to Transcend Fear", b2.chapters[0].title
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
    b.sample_chapter.title = "Understanding the Risks"
    assert_equal "Understanding the Risks", b.g('sample_chapter')['title']
    b.insert!
    b = Book.find_one(b.id)
    assert_equal "Understanding the Risks", b.sample_chapter.title
    assert_equal "Understanding the Risks", b.g('sample_chapter')['title']
  end
end
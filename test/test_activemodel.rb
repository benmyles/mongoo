require 'helper'

class TestActivemodel < Test::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    [TvShow].each do |obj|
      obj.drop
      obj.create_indexes
    end
    @model = TvShow.new
  end
end


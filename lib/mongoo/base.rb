module Mongoo
  class Base < Mongoo::Core

    include Mongoo::Changelog
    include Mongoo::Persistence
    include Mongoo::Modifiers

    extend ActiveModel::Callbacks

    define_model_callbacks :insert, :update, :remove

  end
end
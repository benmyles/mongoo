module Mongoo
  class Base < Mongoo::Core

    include Mongoo::Changelog
    include Mongoo::Persistence
    include Mongoo::Modifiers

    extend ActiveModel::Callbacks

    define_model_callbacks :insert, :update, :remove

    def embedded_array_proxy(attrib, klass)
      Mongoo::Embedded::ArrayProxy.new(self, attrib, klass)
    end

    def embedded_hash_proxy(attrib, klass)
      Mongoo::Embedded::HashProxy.new(self, attrib, klass)
    end

    def embedded_doc(attrib, klass)
      klass.new(self, attrib)
    end

  end
end
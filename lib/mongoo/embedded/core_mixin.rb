module Mongoo
  module Embedded
    module CoreMixin
      extend ActiveSupport::Concern

      module ClassMethods
      end # ClassMethods

      module InstanceMethods
        def embedded_hash_proxy(attrib, klass)
          Mongoo::Embedded::HashProxy.new(self, attrib, klass)
        end

        def embedded_array_proxy(attrib, klass)
          Mongoo::Embedded::ArrayProxy.new(self, attrib, klass)
        end

        def embedded_doc(attrib, klass)
          klass.new(self, attrib)
        end
      end # InstanceMethods
    end # CoreMixin
  end # Embedded
end # Mongoo
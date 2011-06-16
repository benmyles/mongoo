module Mongoo
  module Attributes
    module DescribeDsl
      def attribute(name, opts={})
        raise ArgumentError.new("missing :type") unless opts[:type]
        @klass.attributes[name.to_s] = opts
        true
      end

      def define_attribute_methods
        @klass.attributes_tree(only_definable: true).each do |name, val|
          if val.is_a?(Hash)
            blk = Proc.new { Mongoo::AttributeProxy.new(val, [name], self) }
            @klass.send(:define_method, name, &blk)
          else
            blk = Proc.new { get(name) }
            @klass.send(:define_method, name, &blk)
            blk = Proc.new { |val| set(name, val) }
            @klass.send(:define_method, "#{name}=", &blk)
          end
        end
      end # define_attribute_methods
      protected :define_attribute_methods
    end # DescribeDsl
  end # Attributes
end # Mongoo

class Mongoo::DescribeDsl
  include Mongoo::Attributes::DescribeDsl
end

Mongoo::DescribeDsl.after_describe << :define_attribute_methods
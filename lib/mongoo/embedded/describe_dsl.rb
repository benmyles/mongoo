module Mongoo
  module Embedded
    module DescribeDsl
      def embeds_one(attrib_key, opts)
        raise(ArgumentError, "missing opt :class") unless opts[:class]
        define_embeds_one_method(attrib_key, opts)
      end

      def embeds_many(attrib_key, opts)
        raise(ArgumentError, "missing opt :class") unless opts[:class]
        define_embeds_many_method(attrib_key, opts)
      end

      def define_embeds_many_method(attrib_key, opts)
        as = attrib_key
        attrib_key = "embedded_#{attrib_key}"

        attribute(attrib_key, :type => :hash)

        blk = Proc.new {
          if val = instance_variable_get("@#{as}")
            val
          else
            instance_variable_set("@#{as}",
              embedded_hash_proxy(get_or_set(attrib_key,{}), eval(opts[:class])))
          end
        }
        @klass.send(:define_method, as, &blk)

        unless opts[:validate] == false
          blk = Proc.new {
            send(as).each do |k,v|
              unless v.valid?
                v.errors.each do |field, messages|
                  errors.add "#{attrib_key}.#{k}.#{field}", messages
                end
              end
            end
          }
          @klass.send(:define_method, "validate_#{as}", &blk)
          @klass.validate "validate_#{as}"
        end
      end # define_embeds_many_method
      protected :define_embeds_many_method

      def define_embeds_one_method(attrib_key, opts)
        as = attrib_key
        attrib_key = "embedded_#{attrib_key}"

        attribute(attrib_key, :type => :hash)

        blk = Proc.new {
          if val = instance_variable_get("@#{as}")
            val
          else
            if hash = get(attrib_key)
              instance_variable_set("@#{as}",
                embedded_doc(hash, eval(opts[:class])))
            end
          end
        }
        @klass.send(:define_method, as, &blk)

        blk = Proc.new { |obj|
          set(attrib_key, (obj.nil? ? nil : obj.to_hash))
          send("#{as}")
        }
        @klass.send(:define_method, "#{as}=", &blk)

        unless opts[:validate] == false
          blk = Proc.new {
            if v = send(as)
              unless v.valid?
                v.errors.each do |field, messages|
                  errors.add "#{attrib_key}.#{field}", messages
                end
              end
            end
          }
          @klass.send(:define_method, "validate_#{as}", &blk)
          @klass.validate "validate_#{as}"
        end
      end # define_embeds_one_method
      protected :define_embeds_one_method
    end # DescribeDsl
  end # Embedded
end

class Mongoo::DescribeDsl
  include Mongoo::Embedded::DescribeDsl
end

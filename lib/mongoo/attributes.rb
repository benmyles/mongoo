class Mongoo::UnknownAttributeError < Exception; end

module Mongoo::Attributes
  extend ActiveSupport::Concern

  module ClassMethods
    def attributes
      if @attributes
        @attributes
      else
        @attributes = {}
      end
    end

    def attributes_tree
      tree = {}
      self.attributes.each do |name, opts|
        parts = name.split(".")
        curr_branch = tree
        while part = parts.shift
          if !parts.empty?
            curr_branch[part.to_s] ||= {}
            curr_branch = curr_branch[part.to_s]
          else
            curr_branch[part.to_s] = opts[:type]
          end
        end
      end
      tree
    end

    def known_attribute?(k)
      k == "_id" || self.attributes[k.to_s]
    end
  end # ClassMethods

  module InstanceMethods
    def known_attribute?(k)
      self.class.known_attribute?(k)
    end

    def read_attribute_for_validation(key)
      get_attribute(key)
    end

    def get_attribute(k)
      unless known_attribute?(k)
        raise Mongoo::UnknownAttributeError, k
      end
      mongohash.dot_get(k.to_s)
    end
    alias :get :get_attribute
    alias :g   :get_attribute

    def set_attribute(k,v)
      unless known_attribute?(k)
        if self.respond_to?("#{k}=")
          self.send("#{k}=", v)
          return v
        else
          raise Mongoo::UnknownAttributeError, k
        end
      end
      unless k.to_s == "_id" || v.nil?
        field_type = self.class.attributes[k.to_s][:type]
        v = Mongoo::AttributeSanitizer.sanitize(field_type, v)
      end
      mongohash.dot_set(k.to_s,v); v
    end
    alias :set :set_attribute
    alias :s   :set_attribute

    def get_or_set_attribute(k, v)
      get_attribute(k) || set_attribute(k, v)
    end
    alias :get_or_set :get_or_set_attribute
    alias :gs :get_or_set_attribute

    def unset_attribute(k)
      mongohash.dot_delete(k); true
    end
    alias :unset :unset_attribute
    alias :u :unset_attribute

    def set_attributes(k_v_pairs)
      k_v_pairs.each do |k,v|
        set_attribute(k,v)
      end
    end
    alias :sets :set_attributes

    def get_attributes(keys)
      found = {}
      keys.each { |k| found[k.to_s] = get_attribute(k) }
      found
    end
    alias :gets :get_attributes

    def unset_attributes(keys)
      keys.each { |k| unset_attribute(k) }; true
    end
    alias :unsets :unset_attributes

    def attributes
      mongohash.to_key_value
    end

    def id
      get "_id"
    end

    def id=(val)
      set "_id", val
    end
  end # InstanceMethods
end
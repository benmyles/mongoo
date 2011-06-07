module Mongoo
  class UnknownAttributeError < Exception; end

  class Core
    include ActiveModel::Validations
    extend  ActiveModel::Naming

    def self.embeds_meta
      Mongoo::EMBEDS_META[self.to_s] ||= {}
    end

    def self.embeds_many(attrib_key, opts)
      raise(ArgumentError, "missing opt :as")    unless opts[:as]
      raise(ArgumentError, "missing opt :class") unless opts[:class]

      self.embeds_meta["embeds_many"] ||= {}
      self.embeds_meta["embeds_many"][attrib_key] = opts

      define_embeds_many_methods
    end

    def self.define_embeds_many_methods
      (self.embeds_meta["embeds_many"] || {}).each do |attrib_key, opts|
        define_method(opts[:as]) do
          if val = instance_variable_get("@#{opts[:as]}")
            val
          else
            instance_variable_set("@#{opts[:as]}",
              embedded_hash_proxy(get_or_set(attrib_key,{}), eval(opts[:class])))
          end
        end # define_method
        unless opts[:validate] == false
          define_method("validate_#{opts[:as]}") do
            send(opts[:as]).each do |k,v|
              unless v.valid?
                v.errors.each do |field, messages|
                  errors.add "#{attrib_key}.#{k}.#{field}", messages
                end
              end
            end
          end # define_method
          validate "validate_#{opts[:as]}"
        end
      end
    end

    def self.embeds_one(attrib_key, opts)
      raise(ArgumentError, "missing opt :as")    unless opts[:as]
      raise(ArgumentError, "missing opt :class") unless opts[:class]

      self.embeds_meta["embeds_one"] ||= {}
      self.embeds_meta["embeds_one"][attrib_key] = opts

      define_embeds_one_methods
    end

    def self.define_embeds_one_methods
      (self.embeds_meta["embeds_one"] || {}).each do |attrib_key, opts|
        define_method(opts[:as]) do
          if val = instance_variable_get("@#{opts[:as]}")
            val
          else
            if hash = get(attrib_key)
              instance_variable_set("@#{opts[:as]}",
                embedded_doc(hash, eval(opts[:class])))
            end
          end
        end

        define_method("#{opts[:as]}=") do |obj|
          set(attrib_key, (obj.nil? ? nil : obj.to_hash))
          send("#{opts[:as]}")
        end

        unless opts[:validate] == false
          define_method("validate_#{opts[:as]}") do
            if v = send(opts[:as])
              unless v.valid?
                v.errors.each do |field, messages|
                  errors.add "#{attrib_key}.#{field}", messages
                end
              end
            end
          end # define_method
          validate "validate_#{opts[:as]}"
        end
      end
    end

    def embedded_hash_proxy(attrib, klass)
      Mongoo::Embedded::HashProxy.new(self, attrib, klass)
    end

    def embedded_doc(attrib, klass)
      klass.new(self, attrib)
    end

    def self.attribute(name, opts={})
      raise ArgumentError.new("missing :type") unless opts[:type]
      self.attributes[name.to_s] = opts
      define_attribute_methods
      true
    end

    def self.attributes
      Mongoo::ATTRIBUTE_META[self.to_s] ||= {}
    end

    def self.attributes_tree
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

    def self.define_attribute_methods
      define_method("id") do
        get("_id")
      end
      define_method("id=") do |val|
        set("_id", val)
      end

      self.attributes_tree.each do |name, val|
        if val.is_a?(Hash)
          define_method(name) do
            AttributeProxy.new(val, [name], self)
          end
        else
          define_method(name) do
            get(name)
          end
          define_method("#{name}=") do |val|
            set(name, val)
          end
        end
      end
    end

    def self.known_attribute?(k)
      k == "_id" || self.attributes[k.to_s]
    end

    def initialize(hash={}, persisted=false)
      @persisted = persisted
      init_from_hash(hash)
      set_persisted_mongohash((persisted? ? mongohash : nil))
    end

    def ==(val)
      if val.class.to_s == self.class.to_s
        if val.persisted?
          val.id == self.id
        else
          self.mongohash.raw_hash == val.mongohash.raw_hash
        end
      end
    end

    def known_attribute?(k)
      self.class.known_attribute?(k)
    end

    def read_attribute_for_validation(key)
      get_attribute(key)
    end

    def get_attribute(k)
      unless known_attribute?(k)
        raise UnknownAttributeError, k
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
          raise UnknownAttributeError, k
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

    def merge!(hash)
      if hash.is_a?(Mongoo::Mongohash)
        hash = hash.raw_hash
      end
      hash.deep_stringify_keys!
      hash = mongohash.raw_hash.deep_merge(hash)
      set_mongohash( Mongoo::Mongohash.new(hash) )
      mongohash
    end

    def init_from_hash(hash)
      unless hash.is_a?(Mongoo::Mongohash)
        hash = Mongoo::Mongohash.new(hash)
      end
      set_mongohash hash
    end
    protected :init_from_hash

    def set_mongohash(mongohash)
      @mongohash = mongohash
    end
    protected :set_mongohash

    def mongohash
      @mongohash
    end

    def set_persisted_mongohash(hash)
      @serialized_persisted_mongohash = Marshal.dump(hash)
      @persisted_mongohash = nil
      true
    end
    protected :set_persisted_mongohash

    def persisted_mongohash
      @persisted_mongohash ||= begin
        if @serialized_persisted_mongohash
          Marshal.load(@serialized_persisted_mongohash)
        end
      end
    end

    def to_hash
      mongohash.to_hash
    end
  end # Core
end # Mongoo
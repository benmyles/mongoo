module Mongoo
  class UnknownAttributeError < Exception; end

  class Base

    include Mongoo::Persistence
    include Mongoo::Modifiers

    extend ActiveModel::Callbacks
    extend ActiveModel::Naming

    define_model_callbacks :insert, :update, :remove

    def self.validators
      Mongoo::VALIDATOR_META[self.to_s] ||= []
    end

    def self.validator(regex, _proc)
      self.validators << [regex, _proc]
      true
    end

    def self.input_transformers
      Mongoo::INPUT_TRANSFORMER_META[self.to_s] ||= []
    end

    def self.input_transformer(regex, _proc, opts={})
      self.input_transformers << [regex, _proc, opts]
      true
    end

    def self.output_transformers
      Mongoo::OUTPUT_TRANSFORMER_META[self.to_s] ||= []
    end

    def self.output_transformer(regex, _proc, opts={})
      self.output_transformers << [regex, _proc, opts]
      true
    end

    def initialize(hash={}, persisted=false)
      @persisted = persisted
      init_from_hash(hash)
    end

    def ==(val)
      if val.class.to_s == self.class.to_s
        if val.persisted?
          val["_id"] == self["_id"]
        else
          self.document == val.document
        end
      end
    end

    def [](k)
      document[k]
    end

    def []=(k,v)
      document[k] = v
    end

    def get_attribute(k, opts={})
      document.get(k, opts)
    end
    alias :get :get_attribute
    alias :g   :get_attribute

    def set_attribute(k, v, opts={})
      document.set(k, v, opts)
    end
    alias :set :set_attribute
    alias :s   :set_attribute

    def set_orig_attribute(k, v, opts={})
      document.set_orig(k, v, opts)
    end

    alias :set_orig :set_orig_attribute

    def unset_attribute(k)
      document.unset(k)
    end
    alias :unset :unset_attribute
    alias :u :unset_attribute

    def unset_orig_attribute(k)
      document.unset_orig(k)
    end

    alias :unset_orig :unset_orig_attribute

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

    def clear_caches!
      document.clear_transformer_cache!
    end

    def errors
      document.errors
    end

    def valid?
      errors.blank?
    end

    def merge!(obj)
      if obj.is_a?(Hash)
        document.merge_in_hash!(hash)
      elsif obj.is_a?(Mongoo::Document)
        document.merge_in_document!(obj)
      else
        false
      end
    end

    def init_from_hash(hash)
      validators = self.class.validators.collect do |regex, _proc|
        Mongoo::Document::Validator.new(regex, _proc)
      end

      input_transformers = self.class.input_transformers.collect do |regex, _proc, opts|
        Mongoo::Document::Transformer.new(regex, _proc, opts)
      end

      output_transformers = self.class.output_transformers.collect do |regex, _proc, opts|
        Mongoo::Document::Transformer.new(regex, _proc, opts)
      end

      set_document Mongoo::Document.new(hash, { validators: validators,
                                                input_transformers: input_transformers,
                                                output_transformers: output_transformers })
    end
    protected :init_from_hash

    def set_document(document)
      @document = document
    end
    protected :set_document

    def document
      @document
    end
  end
end
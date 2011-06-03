module Mongoo
  class Document

    class Validator
      attr_accessor :key_regex, :validation_procs

      def initialize(key_regex, validation_procs)
        self.key_regex = key_regex
        self.validation_procs = Array(validation_procs)
      end

      # proc must return: nil or error_message
      def validate(field, val)
        if field =~ self.key_regex
          messages = nil
          validation_procs.each do |p|
            res = p.call(val)
            if res && !res.blank?
              messages = Array(res)
              break
            end
          end
          messages
        else
          nil
        end
      end
    end

    class Transformer
      attr_accessor :key_regex, :transformer_proc, :global_opts

      def initialize(key_regex, transformer_proc, global_opts={})
        self.key_regex = key_regex
        self.transformer_proc = transformer_proc
        self.global_opts = global_opts
      end

      def clear_cache!
        @cache = nil
      end

      # proc must return: new_value
      def transform(field, val, opts={})
        if field =~ self.key_regex
          @cache ||= {}
          @cache[field] = nil unless global_opts[:cache]
          @cache[field] ||= begin
            val = Marshal.load(Marshal.dump(val)) if opts[:dup]
            transformer_proc.call(val)
          end
        else
          val
        end
      end
    end

    attr_accessor :map, :validators, :input_transformers, :output_transformers

    def initialize(hash={}, opts={})
      self.validators          = opts[:validators] || []
      self.input_transformers  = opts[:input_transformers] || []
      self.output_transformers = opts[:output_transformers] || []
      self.map                 = {}
      set_fields_from_hash(hash, [])
      reset_serialized_orig_map!
    end

    def reset_serialized_orig_map!
      @serialized_orig_map = Marshal.dump(self.map)
    end

    def register_validator(validator)
      self.validators << validator
    end

    def register_input_transformer(transformer)
      self.input_transformers << transformer
    end

    def register_output_transformer(transformer)
      self.output_transformers << transformer
    end

    def clear_transformer_cache!
      (self.input_transformers + self.output_transformers).each { |t| t.clear_cache! }
    end

    def ==(other_doc)
      self.map == other_doc.map
    end

    def keys
      self.map.keys
    end

    alias :fields :keys

    def errors
      all_errors = {}
      self.map.each do |field, val|
        _errors = validate_field(field, val)
        if _errors && !_errors.blank?
          errors = Array(_errors)
          all_errors[field] ||= []
          all_errors[field] += errors
          all_errors[field].compact!
          all_errors[field].uniq!
        end
      end
      all_errors
    end

    def set(field, val, opts={})
      transform = opts[:transform]
      transform = true unless opts.has_key?(:transform)

      _map = (opts[:map] || self.map)

      if transform
        val = transform_input_field(field, val)
      end

      _map.keys.each do |k|
        _map.delete(k) if k =~ /^#{field}(\..*)?$/
      end

      if val.is_a?(Hash)
        set_fields_from_hash(val, [field], opts)
      else
        _map[field.to_s] = val
      end

      true
    end

    alias :s :set

    def set_orig(field, val, opts={})
      opts[:map] = self.orig_map
      set(field, val, opts)
    end

    def unset(field)
      self.map.delete(field)
    end

    def unset_orig(field)
      self.orig_map.delete(field)
    end

    def get_orig(field, opts={})
      get_from_map(self.orig_map, field, opts)
    end

    def get(field, opts={})
      get_from_map(self.map, field, opts)
    end

    alias :g :get

    def []=(k,v)
      set(k,v)
    end

    def [](k)
      get(k)
    end

    def orig_map
      @orig_map ||= Marshal.load(@serialized_orig_map)
    end

    def oplog
      map_keys = self.map.keys.sort
      orig_map_keys = orig_map.keys.sort

      removed_keys = orig_map_keys - map_keys

      oplog = {}

      unless removed_keys.empty?
        oplog["$unset"] = {}
        removed_keys.each do |k|
          oplog["$unset"][k] = 1
        end
      end

      map_keys.each do |k|
        if self.map[k] != orig_map[k]
          oplog["$set"]  ||= {}
          oplog["$set"][k] = get(k, { transform: false })
        end
      end

      oplog
    end

    def to_hash(opts={})
      opts[:transform] = false unless opts.has_key?(:transform)

      hash = {}
      self.keys.each do |k|
        this_hash  = hash
        path_parts = k.split(".")
        last_part  = path_parts.pop
        path_parts.each do |part|
          this_hash[part] ||= {}
          this_hash = this_hash[part]
        end
        this_hash[last_part] = get(k, { transform: opts[:transform] })
      end; hash
    end

    def merge_in_hash!(hash)
      set_fields_from_hash(hash, [])
    end

    def merge_in_document!(document)
      document.keys.each do |key|
        set(key, document.get(key))
      end
      true
    end

    def transform_input_field(field, val)
      self.input_transformers.each do |transformer|
        val = transformer.transform(field, val)
      end; val
    end

    def transform_output_field(field, val)
      self.output_transformers.each do |transformer|
        val = transformer.transform(field, val, { dup: true })
      end; val
    end

  protected

    def get_from_map(_map, field, opts)
      transform = opts[:transform]
      transform = true unless opts.has_key?(:transform)

      val = _map[field.to_s]
      if transform
        val = transform_output_field(field, val)
      end
      val
    end

    def validate_field(field, val)
      errors = nil

      self.validators.each do |validator|
        _errors = validator.validate(field, val)
        if _errors
          errors ||= []
          errors  += Array(_errors).compact
        end
      end

      errors
    end

    def set_fields_from_hash(hash, prefix, set_opts={})
      hash.each do |k,v|
        path = [prefix, k].flatten
        set(path.join("."), v, set_opts)
      end
    end

  end
end
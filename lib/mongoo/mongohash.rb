module Mongoo
  class Mongohash
    extend Forwardable
      
    def_delegators :@raw_hash, :==, :[], :[], :[]=, :clear, :default, :default=, :default_proc, :delete, :delete_if,
                   :each, :each_key, :each_pair, :each_value, :empty?, :fetch, :has_key?, :has_value?, :include?,
                   :index, :indexes, :indices, :initialize_copy, :inspect, :invert, :key?, :keys, :length, :member?,
                   :merge, :merge!, :pretty_print, :pretty_print_cycle, :rehash, :reject, :reject!, :replace, :select,
                   :shift, :size, :sort, :store, :to_a, :to_hash, :to_s, :update, :value?, :values, :values_at
    
    attr_reader :raw_hash
    
    def initialize(hash={})
      hash = hash.to_hash unless hash.is_a?(Hash)
      @raw_hash = hash.deep_stringify_keys
    end

    def deep_clone
      Mongoo::Mongohash.new(Marshal.load(Marshal.dump self.raw_hash))
    end
    
    def dot_set(k,v)
      parts    = k.to_s.split(".")
      curr_val = to_hash
      while !parts.empty?
        part = parts.shift
        if parts.empty?
          curr_val[part] = v
        else
          curr_val[part] ||= {}
          curr_val = curr_val[part]
        end
      end
      true
    end
    
    def dot_get(k)
      parts    = k.to_s.split(".")
      curr_val = to_hash
      while !parts.empty?
        part = parts.shift
        curr_val = curr_val[part]
        return curr_val unless curr_val.is_a?(Hash)
      end
      curr_val
    end
    
    def dot_delete(k)
      parts    = k.to_s.split(".")
      curr_val = to_hash
      while !parts.empty?
        part = parts.shift
        if parts.empty?
          curr_val.delete(part)
          return true
        else
          curr_val = curr_val[part]
        end
      end
      false
    end
    
    def dot_list(curr_hash=self.to_hash, path=[])
      list = []
      curr_hash.each do |k,v|
        if v.is_a?(Hash)
          list.concat dot_list(v, (path + [k]))
        else
          list << (path + [k]).join(".")
        end
      end
      list
    end
    
    def to_key_value
      kv = {}; dot_list.collect { |k| kv[k] = dot_get(k) }; kv
    end
  end
end
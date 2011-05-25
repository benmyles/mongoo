module Mongoo
  module HashExt
    def deep_stringify_keys
      deep_clone.deep_stringify_keys!
    end

    def deep_stringify_keys!
      keys.each do |key|
        self[key.to_s] = delete(key)
        if self[key.to_s].is_a?(Hash)
          self[key.to_s].deep_stringify_keys!
        end
      end
      self
    end

    def deep_clone
      Marshal.load(Marshal.dump(self))
    end

    def to_mongoo
      if self["_mongoo_class"]
        self["_mongoo_class"].new(self, true)
      end
    end
  end
end

class Hash
  include Mongoo::HashExt
end
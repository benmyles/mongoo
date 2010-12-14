module Mongoo
  module Changelog
    
    def changelog
      persisted_mongohash_kv = (self.persisted_mongohash || Mongoo::Mongohash.new).to_key_value
      curr_mongohash_kv      = self.mongohash.to_key_value
      
      log = []
      
      persisted_mongohash_kv.each do |k,v|
        unless curr_mongohash_kv.has_key?(k)
          found = nil
          parts = k.split(".")
          while parts.pop
            if !self.mongohash.dot_get(parts.join("."))
              found = [:unset, parts.join("."), 1]
            end
          end
          found ||= [:unset, k, 1]
          log << found
        end
      end
      
      curr_mongohash_kv.each do |k,v|
        if v != persisted_mongohash_kv[k]
          unless log.include?([:set, k, v])
            log << [:set, k, v]
          end
        end
      end
      
      log.uniq
    end
    
  end
end
module Mongoo
  class IdentityMap

    class << self

      def on!
        @on = true
      end

      def on?
        @on == true
      end

      def off!
        @on = false
        if Thread.current[:mongoo]
          Thread.current[:mongoo][:identity_map] = nil
        end; true
      end

      def off?
        @on == false
      end

      def store
        return nil unless on?
        Thread.current[:mongoo] ||= {}
        Thread.current[:mongoo][:identity_map] ||= {}
        Thread.current[:mongoo][:identity_map][:store] ||= {}
      end

      def simple_query?(query, opts)
        return false if query.nil?
        return false unless opts.blank?
        return true if query.is_a?(BSON::ObjectId)
        return true if [[:_id], ["_id"]].include?(query.keys)
        false
      end

      def read(id)
        if store
          if id.is_a?(BSON::ObjectId)
            store[id.to_s]
          elsif id.is_a?(Hash)
            store[(id[:_id] || id["_id"]).to_s]
          end
        end
      end

      def write(doc)
        if store && !store.has_key?(doc.id.to_s)
          store[doc.id.to_s] = doc
        end
      end

      def flush!
        if store
          Thread.current[:mongoo][:identity_map][:store] = {}
          true
        end
      end

    end

  end
end
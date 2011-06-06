module Mongoo
  class ModifierUpdateError < Exception; end
  class UnknownAttributeError < Exception; end

  class ModifierBuilder
    def initialize(opts, doc)
      @opts  = opts
      @doc   = doc
      @queue = {}
      @key_prefix = opts[:key_prefix] || ""
    end

    def known_attribute?(k)
      @doc.known_attribute?("#{@key_prefix}#{k}")
    end

    def sanitize_value(k,v)
      k = "#{@key_prefix}#{k}"
      if known_attribute?(k)
        field_type = @doc.class.attributes[k][:type]
        Mongoo::AttributeSanitizer.sanitize(field_type, v)
      else
        v
      end
    end

    def inc(k, v=1)
      v = sanitize_value(k,v)
      @queue["$inc"] ||= {}
      @queue["$inc"]["#{@key_prefix}#{k}"] = v
    end

    def set(k,v)
      v = sanitize_value(k,v)
      @queue["$set"] ||= {}
      @queue["$set"]["#{@key_prefix}#{k}"] = v
    end

    def unset(k)
      @queue["$unset"] ||= {}
      @queue["$unset"]["#{@key_prefix}#{k}"] = 1
    end

    def push(k, v)
      @queue["$push"] ||= {}
      @queue["$push"]["#{@key_prefix}#{k}"] = v
    end

    def push_all(k, v)
      @queue["$pushAll"] ||= {}
      @queue["$pushAll"]["#{@key_prefix}#{k}"] = v
    end

    def add_to_set(k,v)
      @queue["$addToSet"] ||= {}
      @queue["$addToSet"]["#{@key_prefix}#{k}"] = v
    end

    def pop(k)
      @queue["$pop"] ||= {}
      @queue["$pop"]["#{@key_prefix}#{k}"] = 1
    end

    def pull(k, v)
      @queue["$pull"] ||= {}
      @queue["$pull"]["#{@key_prefix}#{k}"] = v
    end

    def pull_all(k, v)
      @queue["$pullAll"] ||= {}
      @queue["$pullAll"]["#{@key_prefix}#{k}"] = v
    end

    def run!
      if @queue.blank?
        raise ModifierUpdateError, "modifier update queue is empty"
      end

      update_query = { "_id" => @doc.id }
      if @opts[:only_if_current] == true
        @queue.each do |op, op_queue|
          op_queue.each do |k,v|
            update_query[k] = @doc.persisted_mongohash.dot_get(k)
          end
        end
        @opts[:update_opts] ||= {}
        @opts[:update_opts][:safe] = true
      end

      if @opts[:find_and_modify]
        ret = @doc.collection.find_and_modify(query: update_query,
                                              update: @queue,
                                              new: true)
        @doc.reload(ret)
      else
        update_opts = @opts.delete(:update_opts) || {}
        ret = @doc.collection.update(update_query, @queue, update_opts)
        if !ret.is_a?(Hash) || (ret["err"] == nil && ret["n"] == 1)
          @queue.each do |op, op_queue|
            op_queue.each do |k, v|
              case op
              when "$inc" then
                new_val = @doc.persisted_mongohash.dot_get(k).to_i + v
                @doc.mongohash.dot_set( k, new_val )
                @doc.persisted_mongohash.dot_set( k, new_val )
              when "$set" then
                @doc.mongohash.dot_set( k, v )
                @doc.persisted_mongohash.dot_set( k, v )
              when "$unset" then
                @doc.mongohash.dot_delete( k )
                @doc.persisted_mongohash.dot_delete( k )
              when "$push" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || []) + [v]
                @doc.mongohash.dot_set( k, new_val )
                @doc.persisted_mongohash.dot_set( k, new_val )
              when "$pushAll" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || []) + v
                @doc.mongohash.dot_set( k, new_val )
                @doc.persisted_mongohash.dot_set( k, new_val )
              when "$addToSet" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || [])
                new_val << v unless new_val.include?(v)
                @doc.mongohash.dot_set(k, new_val)
                @doc.persisted_mongohash.dot_set(k, new_val)
              when "$pop" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || [])
                new_val.pop
                @doc.mongohash.dot_set(k, new_val)
                @doc.persisted_mongohash.dot_set(k, new_val)
              when "$pull" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || [])
                new_val.delete(v)
                @doc.mongohash.dot_set(k, new_val)
                @doc.persisted_mongohash.dot_set(k, new_val)
              when "$pullAll" then
                new_val = (@doc.persisted_mongohash.dot_get(k) || [])
                v.each do |val|
                  new_val.delete(val)
                end
                @doc.mongohash.dot_set(k, new_val)
                @doc.persisted_mongohash.dot_set(k, new_val)
              end
            end
          end # @queue.each
          true
        else
          raise ModifierUpdateError, ret.inspect
        end
      end # if opts[:find_any_modify]
    end
  end

  module Modifiers

    def mod(opts={}, &block)
      builder = ModifierBuilder.new(opts, self)
      block.call(builder)
      builder.run!
    end

    def mod!(opts={}, &block)
      opts[:update_opts] ||= {}
      opts[:update_opts][:safe] = true
      mod(opts, &block)
    end

  end
end
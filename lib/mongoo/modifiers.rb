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

    def cast_value(v)
      if v.is_a?(Mongoo::Embedded::Base)
        return v.to_hash
      end; v
    end

    def inc(k, v=1)
      v = sanitize_value(k,v)
      @queue["$inc"] ||= {}
      @queue["$inc"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def set(k,v)
      v = sanitize_value(k,v)
      @queue["$set"] ||= {}
      @queue["$set"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def unset(k)
      @queue["$unset"] ||= {}
      @queue["$unset"]["#{@key_prefix}#{k}"] = 1
    end

    def push(k, v)
      @queue["$push"] ||= {}
      @queue["$push"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def push_all(k, v)
      @queue["$pushAll"] ||= {}
      @queue["$pushAll"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def add_to_set(k,v)
      @queue["$addToSet"] ||= {}
      @queue["$addToSet"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def pop(k)
      @queue["$pop"] ||= {}
      @queue["$pop"]["#{@key_prefix}#{k}"] = 1
    end

    def pull(k, v)
      @queue["$pull"] ||= {}
      @queue["$pull"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def pull_all(k, v)
      @queue["$pullAll"] ||= {}
      @queue["$pullAll"]["#{@key_prefix}#{k}"] = cast_value(v)
    end

    def run!
      if @queue.blank?
        raise ModifierUpdateError, "modifier update queue is empty"
      end

      update_query = { "_id" => @doc.id }
      update_query.merge!(@opts[:q]) if @opts[:q]

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
                unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                @doc.persisted_mongohash.dot_get(k) << v
                @doc.mongohash.dot_get(k) << v
              when "$pushAll" then
                unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                @doc.persisted_mongohash.dot_get(k).concat(v)
                @doc.mongohash.dot_get(k).concat(v)
              when "$addToSet" then
                unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                unless @doc.persisted_mongohash.dot_get(k).include?(v)
                  @doc.persisted_mongohash.dot_get(k) << v
                end
                unless @doc.mongohash.dot_get(k).include?(v)
                  @doc.mongohash.dot_get(k) << v
                end
              when "$pop" then
               unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                @doc.persisted_mongohash.dot_get(k).pop
                @doc.mongohash.dot_get(k).pop
              when "$pull" then
                unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                @doc.persisted_mongohash.dot_get(k).delete(v)
                @doc.mongohash.dot_get(k).delete(v)
              when "$pullAll" then
                unless @doc.persisted_mongohash.dot_get(k)
                  @doc.persisted_mongohash.dot_set(k, [])
                end
                unless @doc.mongohash.dot_get(k)
                  @doc.mongohash.dot_set(k, [])
                end

                v.each do |val|
                  @doc.persisted_mongohash.dot_get(k).delete(val)
                  @doc.mongohash.dot_get(k).delete(val)
                end
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
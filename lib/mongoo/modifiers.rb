module Mongoo
  class ModifierUpdateError < Exception; end
  class UnknownAttributeError < Exception; end

  # When using modifiers we do not run input or output
  # transformers or validations. You are responsible for
  # ensuring the validity and integrity of data in this case.
  class ModifierBuilder
    def initialize(opts, doc)
      @opts  = opts
      @doc   = doc
      @queue = {}
      @key_prefix = opts[:key_prefix] || ""
    end

    def inc(k, v=1)
      @queue["$inc"] ||= {}
      @queue["$inc"]["#{@key_prefix}#{k}"] = v
    end

    def set(k,v)
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
      ret = @doc.collection.update({"_id" => @doc["_id"]}, @queue, @opts)
      if !ret.is_a?(Hash) || (ret["err"] == nil && ret["n"] == 1)
        @queue.each do |op, op_queue|
          op_queue.each do |k, v|
            case op
            when "$inc" then
              new_val = @doc[k].to_i + v
              @doc.set(k, new_val, {transform: false})
              @doc.set_orig(k, new_val, {transform: false})
            when "$set" then
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$unset" then
              @doc.unset(k)
              @doc.unset_orig(k)
            when "$push" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || []) + [v]
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$pushAll" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || []) + v
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$addToSet" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || [])
              new_val << v unless new_val.include?(v)
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$pop" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || [])
              new_val.pop
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$pull" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || [])
              new_val.delete(v)
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            when "$pullAll" then
              new_val = (@doc.persisted_mongohash.dot_get(k) || [])
              v.each do |val|
                new_val.delete(val)
              end
              @doc.set(k, v, {transform: false})
              @doc.set_orig(k, v, {transform: false})
            end
          end
        end
        true
      else
        raise ModifierUpdateError, ret.inspect
      end
    end
  end

  module Modifiers

    def mod(opts={}, &block)
      builder = ModifierBuilder.new(opts, self)
      block.call(builder)
      builder.run!
    end

    def mod!(opts={}, &block)
      mod(opts.merge(:safe => true), &block)
    end

  end
end
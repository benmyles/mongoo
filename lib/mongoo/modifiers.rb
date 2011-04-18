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
    
    def ensure_valid_field!(k)
      unless @doc.known_attribute?("#{@key_prefix}#{k}")
        raise UnknownAttributeError, "#{@key_prefix}#{k}"
      end
    end
    
    def sanitize_value(k,v)
      k = "#{@key_prefix}#{k}"
      field_type = @doc.class.attributes[k][:type]
      Mongoo::AttributeSanitizer.sanitize(field_type, v)
    end
    
    def inc(k, v=1)
      ensure_valid_field!(k)
      v = sanitize_value(k,v)
      @queue["$inc"] ||= {}
      @queue["$inc"]["#{@key_prefix}#{k}"] = v
    end
    
    def set(k,v)
      ensure_valid_field!(k)
      v = sanitize_value(k,v)
      @queue["$set"] ||= {}
      @queue["$set"]["#{@key_prefix}#{k}"] = v
    end
    
    def unset(k)
      ensure_valid_field!(k)
      @queue["$unset"] ||= {}
      @queue["$unset"]["#{@key_prefix}#{k}"] = 1
    end

    def push(k, v)
      ensure_valid_field!(k)
      @queue["$push"] ||= {}
      @queue["$push"]["#{@key_prefix}#{k}"] = v
    end
    
    def push_all(k, v)
      ensure_valid_field!(k)
      @queue["$pushAll"] ||= {}
      @queue["$pushAll"]["#{@key_prefix}#{k}"] = v
    end
    
    def add_to_set(k,v)
      ensure_valid_field!(k)
      @queue["$addToSet"] ||= {}
      @queue["$addToSet"]["#{@key_prefix}#{k}"] = v
    end
    
    def pop(k)
      ensure_valid_field!(k)
      @queue["$pop"] ||= {}
      @queue["$pop"]["#{@key_prefix}#{k}"] = 1
    end
    
    def pull(k, v)
      ensure_valid_field!(k)
      @queue["$pull"] ||= {}
      @queue["$pull"]["#{@key_prefix}#{k}"] = v
    end
    
    def pull_all(k, v)
      ensure_valid_field!(k)
      @queue["$pullAll"] ||= {}
      @queue["$pullAll"]["#{@key_prefix}#{k}"] = v
    end
    
    def run!
      if @queue.blank?
        raise ModifierUpdateError, "modifier update queue is empty"
      end
      ret = @doc.collection.update({"_id" => @doc.id}, @queue, @opts)
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
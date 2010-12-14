module Mongoo
  class AttributeProxy
    
    def initialize(curr_hash, path, doc)
      @curr_hash = curr_hash
      @path      = path
      @doc       = doc
    end
    
    def unset
      @doc.unset @path.join(".")
    end
    
    def mod(opts={}, &block)
      builder = ModifierBuilder.new(opts.merge(:key_prefix => "#{@path.join(".")}."), @doc)
      block.call(builder)
      builder.run!
    end
    
    def mod!(opts={}, &block)
      mod(opts.merge(:safe => true), &block)
    end
    
    def method_missing(name, *args)
      name_s = name.to_s
      setter = false
      setter = true if name_s =~ /\=$/
      name_s.gsub!(/\=$/, '')
      
      if val = @curr_hash[name_s]
        key = (@path + [name_s]).join(".")
        if val.is_a?(Hash) && !@doc.known_attribute?(key)
          if setter
            super
          else
            AttributeProxy.new(val, (@path + [name_s]), @doc)
          end
        else
          setter ? @doc.set(key, args[0]) : @doc.get(key)
        end
      else
        super
      end
    end
    
  end
end
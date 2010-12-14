module Mongoo
  class InvalidAttributeValue < Exception; end
  
  class AttributeSanitizer
    class << self
      def sanitize(field_type, val)
        return val if val.nil?
        
        case field_type.to_sym
        when :string then
          val.is_a?(String) ? val : val.to_s
        when :symbol then
          val.is_a?(Symbol) ? val : val.to_sym
        when :integer then
          val.is_a?(Fixnum) ? val : val.to_i
        when :float then
          val.is_a?(Float) ? val : val.to_f
        when :array then
          val.is_a?(Array) ? val : [val]
        when :bson_object_id then
          val.is_a?(BSON::ObjectId) ? val : BSON::ObjectId(val)
        when :hash then
          val.is_a?(Hash) ? val : raise(InvalidAttributeValue, val.inspect)
        end # case
      end # sanitize
    end # << self
  end # AttributeSanitizer
end # Mongoo
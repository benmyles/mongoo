module Mongoo
  class InvalidAttributeValue < Exception; end

  class AttributeSanitizer
    class << self
      def sanitize(field_type, val)
        return val if val.nil? || field_type.nil?

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
        when :time then
          Time.parse(val.to_s)
        when :db_ref then
          val.is_a?(BSON::DBRef) ? val : BSON::DBRef.new(val.collection.name, val.id)
        when :bool then
          if [true,false].include?(val)
            val
          elsif ["t","1","true","y","yes"].include?(val.to_s.downcase)
            true
          elsif ["f","0","false","n","no"].include?(val.to_s.downcase)
            false
          end
        when :html_escaped_string then
          ERB::Util.html_escape(val.to_s)
        end # case
      end # sanitize
    end # << self
  end # AttributeSanitizer
end # Mongoo
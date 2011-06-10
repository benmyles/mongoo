module Mongoo
  class DescribeDsl
    def self.after_describe
      @after_describe ||= []
    end

    def self.before_describe
      @before_describe ||= []
    end

    def initialize(klass)
      @klass = klass
    end

    def describe(&block)
      Mutex.new.synchronize do
        self.class.before_describe.uniq!
        self.class.after_describe.uniq!

        self.class.before_describe.each do |m|
          send(m)
        end

        block.call(self)

        self.class.after_describe.each do |m|
          send(m)
        end
      end
    end

    def index(*args)
      @klass.send(:index, *args)
    end
  end # DescribeDsl
end # Mongoo
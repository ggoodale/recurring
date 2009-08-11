module Recurring


  # A wrapper for Schedule which allows its arguments to be designated in a block. _Under Construction_
  class DateLanguage
    class << self
      def tell &block
        x = self.new
        x.instance_eval &block
        x
      end
    end
    
    attr_reader :frequency
    
    def every(frequency=1, unit=nil, options={})
      @frequency = frequency
    end
    
    def times string
    end
  end

end


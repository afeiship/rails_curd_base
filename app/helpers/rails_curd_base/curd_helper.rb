require 'rails'

module RailsCurdBase
  module CurdHelper
    class << self
      %w(model_class model fields messages).each do |attr|
        attr_accessor attr;
      end
    end

    #
    # %w(Model model fields messages).each do |el|
    #   define_method el do |inValue|
    #     eval "CurdHelper.#{el} = #{inValue}"
    #   end
    # end

    def model_class(inValue)
      CurdHelper.model_class = inValue
    end

    def model(inValue)
      CurdHelper.model = inValue
    end

    def fields(inValue)
      CurdHelper.fields = inValue
    end

    def messages(inValue)
      CurdHelper.messages = inValue
    end

  end
end
require 'rails'

module RailsCurdBase
  module CurdHelper

    class << self
      attr_accessor :model
      attr_accessor :actions
      attr_accessor :context
    end

    # public helpers
    def model(inValue)
      CurdHelper.model = inValue
    end

    def actions(inValue)
      CurdHelper.actions = inValue
    end

    def context(inValue)
      CurdHelper.context = inValue
    end
  end
end
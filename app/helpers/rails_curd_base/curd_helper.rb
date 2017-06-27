module RailsCurdBase
    module CurdHelper
        class << self
            attr_accessor :model
            attr_accessor :actions
        end


        # Static class:
        class Actions
        end

        class << Actions
            def index
            @items = CurdHelper.model.all
            end
        end


        # public helpers
        def model(inValue)
            CurdHelper.model = inValue
        end

        def actions(inValue)
            CurdHelper.actions = inValue
        end
    end
end
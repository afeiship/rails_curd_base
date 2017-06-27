require 'rails'
include RailsCurdBase::CurdHelper

module RailsCurdBase
    class CurdController < ActionController::Base
        def index 
            @items = CurdHelper::Actions.index
        end

        protected
        def set_item
            @item = model.find(params[:id]);
        end

        # need optimize: 
        def strong_params
            if params[:action] == 'new'
                nil
            else
                params.require(:model).permit!
            end
        end
    end

end

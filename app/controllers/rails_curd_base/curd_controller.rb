require 'rails'
include RailsCurdBase::CurdHelper

module RailsCurdBase

  class CurdController < ActionController::Base

    def index
      @items = CurdHelper::Actions.index
    end

    def show
      @item = CurdHelper::Actions.show(params)
    end

    def edit
      @item = CurdHelper::Actions.edit(params)
    end

  end

end

require 'rails'

include RailsCurdBase::CurdHelper

module RailsCurdBase

  class CurdController < ActionController::Base
    include RailsCurdBase::CurdActions;
  end

end

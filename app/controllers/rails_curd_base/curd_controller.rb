require 'rails'

include RailsCurdBase::CurdHelper

module RailsCurdBase

  class CurdController < ActionController::Base
    include CurdActions
  end

end

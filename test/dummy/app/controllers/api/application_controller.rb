module Api
  class ApplicationController < ActionController::API
    # 全局错误处理
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from StandardError, with: :handle_error

    private

    def record_not_found(exception)
      fail message: exception.message, code: 404
    end

    def handle_error(exception)
      Rails.logger.error "Error: #{exception.class} - #{exception.message}"
      fail message: "Internal server error", code: 500
    end
  end
end

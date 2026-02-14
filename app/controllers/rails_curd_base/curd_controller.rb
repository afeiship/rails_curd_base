module RailsCurdBase
  class CurdController < ActionController::API
    include Queryable

    # === CRUD 基础动作 ===
    before_action :set_resource, only: %i[show update destroy]

    def index
      result = apply_query_with_meta(collection)
      data = {
        query_config[:meta][:rows_key] => serialize_collection(result[:collection]),
      }
      data.merge!(result[:meta]) if result[:meta]
      ok data: data, message: "Retrieved successfully"
    end

    def show
      data = serialize_resource(resource)
      ok data: data
    end

    def create
      @resource = resource_class.new(resource_params)
      if before_save(@resource) && @resource.save
        after_save(@resource)
        data = serialize_resource(@resource)
        ok data: data, message: "Created successfully", code: 201
      else
        fail message: "Validation failed", code: 422, data: { errors: @resource.errors.full_messages }
      end
    end

    def update
      if before_save(resource) && resource.update(resource_params)
        after_save(resource)
        data = serialize_resource(resource)
        ok data: data, message: "Updated successfully"
      else
        fail message: "Validation failed", code: 422, data: { errors: resource.errors.full_messages }
      end
    end

    # === 可选：通用钩子（默认调用 create/update 钩子）===
    def before_save(resource)
      action_name == "create" ? before_create(resource) : before_update(resource)
    end

    def after_save(resource)
      action_name == "create" ? after_create(resource) : after_update(resource)
    end

    # === 子类覆盖这些 ===
    def before_create(resource); true; end
    def after_create(resource); end

    def before_update(resource); true; end
    def after_update(resource); end

    def destroy
      resource.destroy
      ok message: "Deleted successfully", code: 204
    end

    private

    # === 序列化逻辑 ===
    def serialize_resource(resource)
      resource.as_json
    end

    def serialize_collection(collection)
      collection.as_json
    end

    # === 资源推导 ===
    def resource_class
      controller_name.singularize.classify.constantize
    end

    def resource_key
      controller_name.singularize.underscore.to_sym
    end

    def resource
      instance_variable_get("@#{controller_name.singularize}")
    end

    def set_resource
      instance_variable_set("@#{controller_name.singularize}", resource_class.find(params[:id]))
    rescue ActiveRecord::RecordNotFound
      fail message: "Record not found", code: 404
    end

    def collection
      resource_class.all
    end

    def resource_params
      permitted_params = params.require(resource_key)
      permitted_params.permit!
    end
  end
end

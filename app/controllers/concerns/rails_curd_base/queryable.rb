module RailsCurdBase
  module Queryable
    extend ActiveSupport::Concern

    DEFAULT_CONFIG = {
      pagination: {
        enabled: false,
        page_param: :page,
        per_param: :size,
        default_per: 10,
        max_per: 100
      },
      sorting: {
        enabled: false,
        sort_param: :sort,
        default_direction: :asc,
        allowed_fields: []
      },
      searching: {
        enabled: false,
        search_param: :q,
        searchable_fields: []
      },
      filtering: {
        enabled: false,
        filter_param: :filter,
        filterable_fields: []
      },
      meta: {
        enabled: true,
        rows_key: :rows,
        total_key: :total
      }
    }.freeze

    class_methods do
      def supports_query(user_config = {})
        config = DEFAULT_CONFIG.deep_dup
        user_config.each do |key, value|
          if config.key?(key) && value.is_a?(Hash)
            config[key].merge!(value)
          else
            config[key] = value
          end
        end

        define_method(:query_config) { config }
        include InstanceMethods
      end
    end

    module InstanceMethods
      def apply_query_with_meta(scope)
        config = query_config
        meta = {}

        # 应用过滤、搜索、排序（不分页）
        base_scope = scope
        base_scope = apply_filtering(base_scope)    if config[:filtering][:enabled]
        base_scope = apply_searching(base_scope)    if config[:searching][:enabled]
        base_scope = apply_sorting(base_scope)      if config[:sorting][:enabled]

        # 获取总数（用于 meta）
        if config[:meta][:enabled]
          meta[config[:meta][:total_key]] = base_scope.count
        end

        # 应用分页
        paginated_scope = base_scope
        if config[:pagination][:enabled]
          paginated_scope = apply_pagination(base_scope)
        end

        {
          collection: paginated_scope,
          meta: config[:meta][:enabled] ? meta : nil
        }
      end

      private

      def apply_pagination(scope)
        config = query_config[:pagination]
        page = [params[config[:page_param]].to_i, 1].max
        per_input = params[config[:per_param]].to_i
        per = per_input <= 0 ? config[:default_per] : [per_input, config[:max_per]].min
        per = [per, 1].max
        scope.page(page).per(per)
      end

      def apply_sorting(scope)
        config = query_config[:sorting]
        sort_param = params[config[:sort_param]]
        return scope unless sort_param.present?

        direction = sort_param.start_with?('-') ? :desc : :asc
        field = sort_param.delete_prefix('-').to_sym
        connection = scope.connection

        if config[:allowed_fields].empty? || config[:allowed_fields].include?(field)
          quoted_field = connection.quote_column_name(field)
          return scope.order(Arel.sql("#{quoted_field} #{direction}"))
        else
          return scope
        end
      end

      def apply_searching(scope)
        config = query_config[:searching]
        term = params[config[:search_param]]&.strip
        return scope unless term.present?

        searchable_fields = config[:searchable_fields]
        return scope if searchable_fields.empty?

        connection = scope.connection

        terms = Array.new(searchable_fields.size, "%#{term}%")
        conditions = searchable_fields.map do |f|
          "LOWER(#{connection.quote_column_name(f)}) LIKE LOWER(?)"
        end.join(' OR ')
        scope.where(conditions, *terms)
      end

      def apply_filtering(scope)
        config = query_config[:filtering]
        raw_filters = params[config[:filter_param]]
        return scope if raw_filters.blank?

        # 1. 获取允许过滤的字段名（字符串数组）
        filterable_fields = config[:filterable_fields].map(&:to_s)

        # 2. permit 这些字段（包括嵌套操作符）
        # 支持两种格式：filter[status]=published 或 filter[status][eq]=published
        permitted = raw_filters.permit(
          *filterable_fields.map { |f| f.to_sym },
          *filterable_fields.map { |f| { f.to_sym => [:eq, :neq, :gt, :gte, :lt, :lte, :in, :nin] } }
        )

        # 3. 转为普通 Hash
        filters = permitted.to_h

        connection = scope.connection

        filters.inject(scope) do |s, (field, value)|
          if value.is_a?(Hash)
            op = value.keys.first&.to_sym
            val = value.values.first
            apply_filter_operation(s, field, op, val)
          else
            s.where("#{connection.quote_column_name(field)} = ?", val_or_array(value))
          end
        end
      end

      def apply_filter_operation(scope, field, op, value)
        connection = scope.connection
        quoted = connection.quote_column_name(field)
        case op
        when :eq  then scope.where("#{quoted} = ?", val_or_array(value))
        when :neq then scope.where("#{quoted} != ?", val_or_array(value))
        when :gt  then scope.where("#{quoted} > ?", value)
        when :gte then scope.where("#{quoted} >= ?", value)
        when :lt  then scope.where("#{quoted} < ?", value)
        when :lte then scope.where("#{quoted} <= ?", value)
        when :in  then scope.where(quoted => Array(value))
        when :nin then scope.where.not(quoted => Array(value))
        else scope
        end
      end

      def val_or_array(val)
        return val unless val.is_a?(String) && val.include?(',')
        val.split(',').map(&:strip)
      end
    end
  end
end

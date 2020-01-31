module ActiveAdmin
  module Axlsx
    module DSL
      delegate(:after_filter,
               :before_filter,
               :column,
               :ignore_columns,
               :delete_columns,
               :only_columns,
               :header_format,
               :header_style,
               :i18n_scope,
               :skip_header,
               :whitelist,
               to: :xlsx_builder,
               prefix: :config)

      def xlsx(options = {}, &block)
        config.xlsx_builder = ActiveAdmin::Axlsx::Builder.new(
          config.resource_class,
          options,
          &block
        )
      end
    end
  end
end

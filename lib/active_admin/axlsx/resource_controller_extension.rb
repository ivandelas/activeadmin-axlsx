module ActiveAdmin
  module Axlsx
    module ResourceControllerExtension
      def self.prepended(base)
        base.send :respond_to, :xlsx, only: :index
      end

      def index
        super do |format|
          format.xlsx do
            xlsx = active_admin_config.xlsx_builder.serialize(xlsx_collection, view_context)
            send_data(xlsx, filename: xlsx_filename,
                            type: Mime::Type.lookup_by_extension(:xlsx))
          end

          yield(format) if block_given?
        end
      end

      def rescue_active_admin_access_denied(exception)
        if request.format == Mime::Type.lookup_by_extension(:xlsx)
          respond_to do |format|
            format.xlsx do
              flash[:error] = "#{exception.message} Review download_links in initializers/active_admin.rb"
              redirect_backwards_or_to_root
            end
          end
        else
          super(exception)
        end
      end

      def xlsx_filename
        timestamp = Time.now.strftime('%Y-%m-%d')
        "#{resource_collection_name.to_s.tr('_', '-')}-#{timestamp}.xlsx"
      end

      def xlsx_collection
        find_collection except: :pagination
      end
    end
  end
end

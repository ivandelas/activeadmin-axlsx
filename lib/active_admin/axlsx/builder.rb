require 'axlsx'

module ActiveAdmin
  module Axlsx
    class Builder
      include MethodOrProcHelper

      def initialize(resource_class, options={}, &block)
        @skip_header = false
        @columns = resource_columns(resource_class)
        parse_options options
        instance_eval &block if block_given?

        # @resource_class = resource_class
        # @columns = []
        # @columns_loaded = false
        # @column_updates = []
      end

      # The default header style
      # @return [Hash]
      def header_style
        @header_style ||= { :bg_color => '00', :fg_color => 'FF', :sz => 12, :alignment => { :horizontal => :center } }
      end

      # This has can be used to override the default header style for your
      # sheet. Any values you provide will be merged with the default styles.
      # Precidence is given to your hash
      # @see https://github.com/randym/axlsx for more details on how to
      # create and apply style.
      def header_style=(style_hash)
        @header_style = header_style.merge(style_hash)
      end

      # Indicates that we do not want to serialize the column headers
      def skip_header
        @skip_header = true
      end

      # The scope to use when looking up column names to generate the report header
      attr_accessor :i18n_scope

      def i18n_scope
        @i18n_scope ||= nil
      end

      # This is the I18n scope that will be used when looking up your
      # colum names in the current I18n locale.
      # If you set it to [:active_admin, :resources, :posts] the 
      # serializer will render the value at active_admin.resources.posts.title in the
      # current translations
      # @note If you do not set this, the column name will be titleized.
      def i18n_scope=(scope)
        @i18n_scope = scope
      end

      # The stored block that will be executed after your report is generated.
      def after_filter(&block)
        @after_filter = block
      end

      # the stored block that will be executed before your report is generated.
      def before_filter(&block)
        @before_filter = block
      end

      # The columns this builder will be serializing
      attr_reader :columns

      # The collection we are serializing.
      # @note This is only available after serialize has been called,
      # and is reset on each subsequent call.
      attr_reader :collection

      # removes all columns from the builder. This is useful when you want to
      # only render specific columns. To remove specific columns use ignore_column.
      def clear_columns
        @columns = []
      end

      # def columns
        # execute each update from @column_updates
        # set @columns_loaded = true
        # load_columns unless @columns_loaded
        # @columns
      # end

      # attr_reader :collection

      # def clear_columns
        # @columns_loaded = true
        # @column_updates = []

        # @columns = []
      # end

      # Clears the default columns array so you can whitelist only the columns you
      # want to export
      def whitelist
        @columns = []
      end

      # Add a column
      # @param [Symbol] name The name of the column.
      # @param [Proc] block A block of code that is executed on the resource
      #                     when generating row data for this column.
      def column(name, &block)
        @columns << Column.new(name, block)
      end

      # removes columns by name
      # each column_name should be a symbol
      def delete_columns(*column_names)
        @columns.delete_if { |column| column_names.include?(column.name) }
      end

      # Serializes the collection provided
      # @return [Axlsx::Package]
      def serialize(collection, view_context = nil)
        @collection = collection
        apply_filter @before_filter
        @view_context = view_context
        # load_columns unless @columns_loaded
        export_collection(collection)
        apply_filter @after_filter
        to_stream
      end

      # alias whitelist clear_columns

      # def column(name, &block)
        # if @columns_loaded
          # columns << Column.new(name, block)
        # else
          # column_lambda = lambda do
            # column(name, &block)
          # end
          # @column_updates << column_lambda
        # end
      # end

      # def delete_columns(*column_names)
        # if @columns_loaded
          # columns.delete_if { |column| column_names.include?(column.name) }
        # else
          # delete_lambda = lambda do
            # delete_columns(*column_names)
          # end
          # @column_updates << delete_lambda
        # end
      # end

      # def only_columns(*column_names)
        # clear_columns
        # column_names.each do |column_name|
          # column column_name
        # end
      # end

      protected

      class Column

        def initialize(name, block = nil)
          @name = name.to_sym
          @data = block || @name
        end

        attr_reader :name, :data

        def localized_name(i18n_scope = nil)
          return name.to_s.titleize unless i18n_scope
          I18n.t name, scope: i18n_scope
        end
      end

      private

      #def load_columns
        # return if @columns_loaded
        # @columns = resource_columns(@resource_class)
        # @columns_loaded = true
        # @column_updates.each(&:call)
        # @column_updates = []
        # columns
      # end

      def to_stream
        stream = package.to_stream.read
        clean_up
        stream
      end

      def clean_up
        @package = @sheet = nil
      end

      def export_collection(collection)
        header_row(collection) unless @skip_header
        collection.each do |resource|
          sheet.add_row resource_data(resource)
        end
      end

      # tranform column names into array of localized strings
      # @return [Array]
      def header_row(collection)
        sheet.add_row header_data_for(collection), { :style => header_style_id }
      end

      def header_data_for(collection)
        resource = collection.first # || @resource_class.new
        columns.map do |column|
          column.localized_name(i18n_scope) if in_scope(resource, column)
        end.compact
      end

      def apply_filter(filter)
        filter&.call(sheet) if filter
      end

      def parse_options(options)
        options.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=") && value != nil
        end
      end

      def resource_data(resource)
        columns.map  do |column|
          call_method_or_proc_on resource, column.data if in_scope(resource, column)
        end
      end

      def in_scope(resource, column)
        return true unless column.name.is_a?(Symbol)

        resource.respond_to?(column.name)
      end

      def sheet
        @sheet ||= package.workbook.add_worksheet
      end

      def package
        @package ||= ::Axlsx::Package.new(use_shared_strings: true)
      end

      def header_style_id
        package.workbook.styles.add_style header_style
      end

      def resource_columns(resource)
        [Column.new(:id)] + resource.content_columns.map do |column|
          Column.new(column.name.to_sym)
        end
      end

      def method_missing(method_name, *arguments)
        if @view_context.respond_to? method_name
          @view_context.send method_name, *arguments
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @view_context.respond_to?(method_name) || super
      end
    end
  end
end

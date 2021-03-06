require 'advanced_reporting_hooks'
require "ruport"
#require "ruport/util"

module Spree
  module AdvancedReporting
    class Engine < Rails::Engine
      config.autoload_paths += %W(#{config.root}/lib)
      def self.activate
        
        Dir.glob(File.join(File.dirname(__FILE__), "../config/locales/*.yml")).each do |c|
          I18n.load_path << File.expand_path(c)
        end
        
        Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator.rb")).each do |c|
          Rails.env.production? ? require(c) : load(c)
        end
        
        Ruport::Formatter::HTML.class_eval do
          # Renders individual rows for the table.
          def build_row(data = self.data)
            @odd = !@odd
            klass = @odd ? "odd" : "even"
            output <<
            "\t\t<tr class=\"#{klass}\">\n\t\t\t<td>" +
              data.to_a.join("</td>\n\t\t\t<td>") +
              "</td>\n\t\t</tr>\n"
          end

          def html_table
            @odd = false
            "<table class=\"table tablesorter\">\n" << yield << "</table>\n"
          end

          def build_table_header
            output << "\t<table class=\"table tablesorter\">\n"
            unless data.column_names.empty? || !options.show_table_headers
              output << "\t\t<thead><tr>\n\t\t\t" +
                data.column_names.map{|a| "<th><span>" + a + "</span></th>"}.join("\n\t\t\t") +
                "</tr></thead>\n"
            end
          end
        end
      end

      config.to_prepare &method(:activate).to_proc
    end
  end
end


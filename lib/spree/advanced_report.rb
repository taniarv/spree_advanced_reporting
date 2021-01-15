module Spree
  class AdvancedReport
    # [ :revenue, :units, :profit, :count, :top_customers, :geo_revenue, :geo_units, :geo_profit]
    AVAILABLE_REPORTS = [:total_digitals, :total_products, :total_payment_methods, :units, :top_products]
    include Ruport
    attr_accessor :orders, :line_items, :product_text, :date_text, :taxon_text, :ruportdata, :data, :params, :taxon, :taxon_id, :product, :product_id, :product_in_taxon, :unfiltered_params, :total, :total_units

    def name
      "Base Advanced Report"
    end

    def description
      "Base Advanced Report"
    end

    def initialize(params)
      self.params = params
      self.data = {}
      self.ruportdata = {}
      self.unfiltered_params = params[:search].blank? ? {} : params[:search].clone

      params[:search] ||= {}
      if params[:search][:completed_at_gt].blank?
        if (Order.count > 0) && Order.minimum(:completed_at)
          params[:search][:completed_at_gt] = Order.minimum(:completed_at).beginning_of_day
        end
      else
        params[:search][:completed_at_gt] = Time.zone.parse(params[:search][:completed_at_gt]).beginning_of_day rescue ""
      end
      if params[:search][:completed_at_lt].blank?
        if (Order.count > 0) && Order.maximum(:completed_at)
          params[:search][:completed_at_lt] = Order.maximum(:completed_at).end_of_day
        end
      else
        params[:search][:completed_at_lt] = Time.zone.parse(params[:search][:completed_at_lt]).end_of_day rescue ""
      end

      params[:search][:completed_at_not_null] = true
      params[:search][:payment_state_eq] = 'paid'
      params[:search][:state_not_eq] = 'canceled'

      search = Order.search(params[:search])
      # self.orders = search.state_does_not_equal('canceled')
      self.orders = search.result
      self.line_items = Spree::LineItem.joins(:order).joins('INNER JOIN "spree_variants" ON "spree_variants"."id" = "spree_line_items"."variant_id"').includes(:variant).where(order: self.orders)
    
      self.product_in_taxon = true
      
      if params[:search][:taxon_id] && params[:search][:taxon_id] != ''
        self.taxon_id = params[:search][:taxon_id]
        self.taxon = Taxon.find(self.taxon_id)
        self.line_items = self.line_items.where("spree_variants.product_id IN (?)", self.taxon.product_ids)
      end
      if params[:search][:product_id] && params[:search][:product_id] != ''
        self.product_id = params[:search][:product_id]
        self.product = Product.find(self.product_id)
        self.line_items = self.line_items.where("spree_variants.product_id = ?", self.product_id)
      end
      
      if self.taxon && self.product && !self.product.taxons.include?(self.taxon)
        self.product_in_taxon = false
      end

      if self.product
        self.product_text = "#{Spree.t(:products)}: <strong>#{self.product.name}</strong><br />"
      end
      if self.taxon
        self.taxon_text = "#{Spree.t(:taxons)}: <strong>#{self.taxon.name}</strong><br />"
      end

      # Above searchlogic date settings
      self.date_text = Spree.t(:date_range)
      if self.unfiltered_params
        if self.unfiltered_params[:completed_at_gt] != '' && self.unfiltered_params[:completed_at_lt] != ''
          self.date_text += " #{Spree.t(:from)} <strong>#{self.unfiltered_params[:completed_at_gt]}</strong> #{Spree.t(:to)} <strong>#{self.unfiltered_params[:completed_at_lt]}</strong>"
        elsif self.unfiltered_params[:completed_at_gt] != ''
          self.date_text += " #{Spree.t(:after)} <strong>#{self.unfiltered_params[:completed_at_gt]}</strong>"
        elsif self.unfiltered_params[:completed_at_lt] != ''
          self.date_text += " #{Spree.t(:before)} <strong>#{self.unfiltered_params[:completed_at_lt]}</strong>"
        else
          self.date_text += " #{Spree.t(:all)}"
        end
      else
        self.date_text += " #{Spree.t(:all)}"
      end
    end

    def download_url(base, format, report_type = nil)
      elements = []
      params[:advanced_reporting] ||= {}
      params[:advanced_reporting]["report_type"] = report_type if report_type
      if params
        [:search, :advanced_reporting].each do |type|
          if params[type]
            params[type].each { |k, v| elements << "#{type}[#{k}]=#{v}" }
          end
        end
      end
      base.gsub!(/^\/\//,'/')
      base + '.' + format + '?' + elements.join('&')
    end

    def revenue(order)
      rev = order.item_total
      if !self.product.nil? && product_in_taxon
        rev = order.line_items.select { |li| li.product == self.product }.inject(0) { |a, b| a += b.quantity * b.price }
      elsif !self.taxon.nil?
        rev = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |a, b| a += b.quantity * b.price }
      end
      self.product_in_taxon ? rev : 0
    end

    def profit(order)
      profit = order.line_items.inject(0) { |profit, li| profit + (li.variant.price - li.variant.cost_price.to_f)*li.quantity }
      if !self.product.nil? && product_in_taxon
        profit = order.line_items.select { |li| li.product == self.product }.inject(0) { |profit, li| profit + (li.variant.price - li.variant.cost_price.to_f)*li.quantity }
      elsif !self.taxon.nil?
        profit = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |profit, li| profit + (li.variant.price - li.variant.cost_price.to_f)*li.quantity }
      end
      self.product_in_taxon ? profit : 0
    end

    def units(order)
      units = order.line_items.sum(:quantity)
      if !self.product.nil? && product_in_taxon
        units = order.line_items.select { |li| li.product == self.product }.inject(0) { |a, b| a += b.quantity }
      elsif !self.taxon.nil?
        units = order.line_items.select { |li| li.product && li.product.taxons.include?(self.taxon) }.inject(0) { |a, b| a += b.quantity }
      end
      self.product_in_taxon ? units : 0
    end

    def order_count(order)
      self.product_in_taxon ? 1 : 0
    end
  end
end

class Spree::AdvancedReport::TotalReport::TotalProducts < Spree::AdvancedReport::TotalReport
  def name
    Spree.t('total_products')
  end

  def description
    Spree.t('total_products_description')
  end

  def initialize(params)
    super(params)
    self.total = 0
    self.total_units = 0
    
    # free_line_items
    self.line_items.joins(:order).where("spree_orders.payment_total = 0").find_each do |li|
      variant = Spree::Variant.with_deleted.find(li.variant_id)
      if variant.present?
        data[variant.product_id] ||= {
          :name => variant.name.to_s,
          # :paper_revenue => 0,
          # :paper_units => 0,
          :digital_revenue => 0,
          :digital_units => 0,
          :paypal_revenue => 0,
          :paypal_units => 0,
          :revenue => 0,
          :units => 0
        }
        if variant.digital?
          data[variant.product_id][:digital_revenue] += li.quantity*li.price 
          data[variant.product_id][:digital_units] += li.quantity
        # else
        #   data[variant.product_id][:paper_revenue] += li.quantity*li.price 
        #   data[variant.product_id][:paper_units] += li.quantity
        end
        data[variant.product_id][:revenue] += li.quantity*li.price 
        data[variant.product_id][:units] += li.quantity
        
        self.total += li.quantity*li.price
        self.total_units += li.quantity
      end
    end

    # paid_line_items
    self.line_items.joins(order: :payments).merge(Spree::Payment.completed).includes(order: :payments).where("spree_orders.payment_total > 0").find_each do |li|
      variant = Spree::Variant.with_deleted.find(li.variant_id)
      if variant.present?
        data[variant.product_id] ||= {
          :name => variant.name.to_s,
          # :paper_revenue => 0,
          # :paper_units => 0,
          :digital_revenue => 0,
          :digital_units => 0,
          :paypal_revenue => 0,
          :paypal_units => 0,
          :revenue => 0,
          :units => 0
        }
        if variant.digital?
          data[variant.product_id][:digital_revenue] += li.quantity*li.price 
          data[variant.product_id][:digital_units] += li.quantity
        # else
        #   data[variant.product_id][:paper_revenue] += li.quantity*li.price 
        #   data[variant.product_id][:paper_units] += li.quantity
        end
        data[variant.product_id][:revenue] += li.quantity*li.price 
        data[variant.product_id][:units] += li.quantity
        
        # PayPal
        if li.order.payments.last.payment_method_id.eql?(2)
          data[variant.product_id][:paypal_revenue] += li.quantity*li.price
          data[variant.product_id][:paypal_units] += li.quantity
        end
        self.total += li.quantity*li.price
        self.total_units += li.quantity
      end
    end
    
    # self.ruportdata = Table(%w[name paper_units paper_revenue digital_units digital_revenue units revenue])
    self.ruportdata = Table(%w[name digital_units digital_revenue paypal_units paypal_revenue units revenue])

    # data.inject({}) { |h, (k, v) | h[k] = v[:units]; h }.sort { |a, b| a[1] <=> b [1] }.reverse.each do |k, v|
    #   ruportdata << { "name" => data[k][:name], "paper_units" => data[k][:paper_units], "paper_revenue" => data[k][:paper_revenue], 
    #     "digital_units" => data[k][:digital_units], "digital_revenue" => data[k][:digital_revenue], "units" => data[k][:units], "revenue" => data[k][:revenue] } 
    # end
    data.inject({}) { |h, (k, v) | h[k] = v[:units]; h }.sort { |a, b| a[1] <=> b [1] }.reverse.each do |k, v|
      ruportdata << { "name" => data[k][:name], 
        "digital_units" => data[k][:digital_units], "digital_revenue" => data[k][:digital_revenue], 
        "paypal_units" => data[k][:paypal_units], "paypal_revenue" => data[k][:paypal_revenue], 
        "units" => data[k][:units], "revenue" => data[k][:revenue] } 
    end
    # ruportdata.replace_column("paper_revenue") { |r| Spree::Money.new(r.paper_revenue).to_s }
    ruportdata.replace_column("digital_revenue") { |r| Spree::Money.new(r.digital_revenue).to_s }
    ruportdata.replace_column("paypal_revenue") { |r| Spree::Money.new(r.paypal_revenue).to_s }
    ruportdata.replace_column("revenue") { |r| Spree::Money.new(r.revenue).to_s }
    
    ruportdata.rename_column("name", Spree.t('adv_report.columns.product_name'))
    # ruportdata.rename_column("paper_units", Spree.t('adv_report.columns.paper_units'))
    # ruportdata.rename_column("paper_revenue", Spree.t('adv_report.columns.paper_revenue'))
    ruportdata.rename_column("digital_units", Spree.t('adv_report.columns.digital_units'))
    ruportdata.rename_column("digital_revenue", Spree.t('adv_report.columns.digital_revenue'))
    ruportdata.rename_column("paypal_units", Spree.t('adv_report.columns.paypal_units'))
    ruportdata.rename_column("paypal_revenue", Spree.t('adv_report.columns.paypal_revenue'))
    ruportdata.rename_column("units", Spree.t('adv_report.columns.units'))
    ruportdata.rename_column("revenue", Spree.t('adv_report.columns.revenue'))
  end
end

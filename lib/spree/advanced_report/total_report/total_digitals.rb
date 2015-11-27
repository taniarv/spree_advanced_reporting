class Spree::AdvancedReport::TotalReport::TotalDigitals < Spree::AdvancedReport::TotalReport
  def name
    Spree.t('total_digitals')
  end

  def description
    Spree.t('total_digitals_description')
  end

  def initialize(params)
    super(params)
    self.total = 0  
    orders.each do |order|
      order.line_items.select{|a|a.digital?}.each do |li|
        if !li.product.nil?
          data[li.product.id] ||= {
            :name => li.product.name.to_s,
            :revenue => 0,
            :units => 0
          }
          data[li.product.id][:revenue] += li.quantity*li.price 
          data[li.product.id][:units] += li.quantity
          self.total += li.quantity*li.price
        end
      end
    end

    self.ruportdata = Table(%w[name units revenue])
    data.inject({}) { |h, (k, v) | h[k] = v[:revenue]; h }.sort { |a, b| a[1] <=> b [1] }.reverse.each do |k, v|
      ruportdata << { "name" => data[k][:name], "units" => data[k][:units], "revenue" => data[k][:revenue] } 
    end
    ruportdata.replace_column("revenue") { |r| Spree::Money.new(r.revenue).to_s }
    ruportdata.rename_column("name", Spree.t('adv_report.columns.product_name'))
    ruportdata.rename_column("units", Spree.t('adv_report.columns.units'))
    ruportdata.rename_column("revenue", Spree.t('adv_report.columns.revenue'))
  end
end

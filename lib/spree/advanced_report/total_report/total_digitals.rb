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
    self.total_units = 0
    
    self.line_items.digital_for_reports.find_each do |li|
      if li.variant.present? && li.product.present? 
        data[li.variant.product_id] ||= {
          name: li.variant.name.to_s,
          revenue: 0,
          units: 0
        }
        data[li.variant.product_id][:revenue] += li.quantity*li.price 
        data[li.variant.product_id][:units] += li.quantity
      else
        data['deleted'] ||= {
          name: '### Eliminados ###',
          revenue: 0,
          units: 0
        }
        data['deleted'][:revenue] += li.quantity*li.price 
        data['deleted'][:units] += li.quantity
      end
      self.total += li.quantity*li.price
      self.total_units += li.quantity
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

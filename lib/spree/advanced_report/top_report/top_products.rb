class Spree::AdvancedReport::TopReport::TopProducts < Spree::AdvancedReport::TopReport
  def name
    Spree.t('top_products')
  end

  def description
    Spree.t('top_products_description')
  end

  def initialize(params, limit)
    super(params)
    self.total = 0
    self.total_units = 0

    Spree::LineItem.joins(:order, :variant).includes(:variant).where(order: orders).find_each do |li|
      if li.product.present?
        data[li.product.id] ||= {
          :name => li.variant.name.to_s,
          :revenue => 0,
          :units => 0
        }
        data[li.variant.product_id][:revenue] += li.quantity*li.price 
        data[li.variant.product_id][:units] += li.quantity
        self.total += li.quantity*li.price
        self.total_units += li.quantity
      end
    end

    self.ruportdata = Table(%w[name Units Revenue])
    data.inject({}) { |h, (k, v) | h[k] = v[:units]; h }.sort { |a, b| a[1] <=> b [1] }.reverse[0..limit].each do |k, v|
      ruportdata << { "name" => data[k][:name], "Units" => data[k][:units], "Revenue" => data[k][:revenue] } 
    end
    ruportdata.replace_column("Revenue") { |r| Spree::Money.new(r.Revenue).to_s }
    ruportdata.rename_column("name", Spree.t('adv_report.columns.product_name'))
    ruportdata.rename_column("units", Spree.t('adv_report.columns.units'))
    ruportdata.rename_column("revenue", Spree.t('adv_report.columns.revenue'))
  end
end

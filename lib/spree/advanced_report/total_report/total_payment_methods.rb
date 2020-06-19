class Spree::AdvancedReport::TotalReport::TotalPaymentMethods < Spree::AdvancedReport::TotalReport
  attr_accessor :payment_method_id

  def name
    Spree.t('total_payment_methods')
  end

  def description
    Spree.t('total_payment_methods_description')
  end

  def initialize(params)
    super(params)
    self.total = 0
    self.total_units = 0
    all_payment_methods = {}
    Spree::PaymentMethod.unscoped.map{|a| all_payment_methods[a.id] = a}
    
    self.orders.joins(:payments).merge(Spree::Payment.completed).includes(:payments).where("spree_orders.payment_total > 0").find_each do |order|
      payment_method = all_payment_methods[order.payments.last.payment_method_id]
      data[payment_method.id] ||= {
        name: payment_method.name,
        revenue: 0,
        units: 0
      }
      data[payment_method.id][:revenue] += order.payment_total
      data[payment_method.id][:units] += 1
      self.total += order.payment_total
      self.total_units += 1
    end
    
    self.ruportdata = Table(%w[name units revenue])
    data.inject({}) { |h, (k, v) | h[k] = v[:revenue]; h }.sort { |a, b| a[1] <=> b [1] }.reverse.each do |k, v|
      ruportdata << { "name" => data[k][:name], "units" => data[k][:units], "revenue" => data[k][:revenue] } 
    end
    ruportdata.replace_column("revenue") { |r| Spree::Money.new(r.revenue).to_s }
    ruportdata.rename_column("name", Spree.t('adv_report.columns.payment_method_name'))
    ruportdata.rename_column("units", Spree.t('adv_report.columns.orders'))
    ruportdata.rename_column("revenue", Spree.t('adv_report.columns.revenue'))
  end
end

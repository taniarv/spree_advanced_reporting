class Spree::AdvancedReport::IncrementReport::Units < Spree::AdvancedReport::IncrementReport
  def name
    Spree.t('adv_report.units')
  end

  def column
    "Units"
  end

  def description
    Spree.t('adv_report.units_description')
  end

  def initialize(params)
    super(params)
    self.total = 0
    self.orders.each do |order|
      date = {}
      INCREMENTS.each do |type|
        date[type] = get_bucket(type, order.completed_at)
        data[type][date[type]] ||= {
          :value => 0, 
          :display => get_display(type, order.completed_at),
        }
      end
      units = units(order)
      INCREMENTS.each { |type| data[type][date[type]][:value] += units }
      self.total += units
    end

    generate_ruport_data
  end
end

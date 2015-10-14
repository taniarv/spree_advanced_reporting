class Spree::AdvancedReport::TotalReport < Spree::AdvancedReport
  attr_accessor :total

  def format_total
    Spree::Money.new(self.total)
  end
end

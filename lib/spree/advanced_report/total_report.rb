class Spree::AdvancedReport::TotalReport < Spree::AdvancedReport
  def format_total
    Spree::Money.new(self.total)
  end
end

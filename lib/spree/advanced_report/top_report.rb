class Spree::AdvancedReport::TopReport < Spree::AdvancedReport
  def format_total
    Spree::Money.new(self.total)
  end
end

Spree::Admin::ReportsController.class_eval do
  before_filter :set_locale
  before_filter :basic_report_setup, actions: [:profit, :revenue, :units, :top_products, :top_customers, 
            :geo_revenue, :geo_units, :count, :total_digitals, :total_products, :total_payment_methods]
  
  def initialize
    # sales_total not included
    super
    Spree::AdvancedReport::AVAILABLE_REPORTS.each {|a| Spree::Admin::ReportsController.add_available_report!(a)}
  end  

  def basic_report_setup
    if params[:search].nil?
      params[:search] = {completed_at_gt: I18n.l(7.day.ago.to_date), completed_at_lt: I18n.l(Date.today)}
    end
    @products = Spree::Product.joins(:translations).includes(:translations).reorder("spree_product_translations.name")
    @taxons = Spree::Taxon.joins(:translations).includes(:translations).reorder("spree_taxon_translations.name")
    @product_id = params[:search][:product_id]
    @taxon_id = params[:search][:taxon_id]
    @completed_at_gt = params[:search][:completed_at_gt]
    @completed_at_lt = params[:search][:completed_at_lt]
    if defined?(MultiDomainExtension)
      @stores = Store.all
    end
  end

  def base_report_render(filename)
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]["report_type"] = params[:advanced_reporting]["report_type"].to_sym if params[:advanced_reporting]["report_type"]
    params[:advanced_reporting]["report_type"] ||= :daily
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/increment_base" }
      format.csv do
        if params[:advanced_reporting]["report_type"] == :all
          send_data @report.all_data.to_csv
        else
          send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv
        end
      end
    end
  end  

  def base_report_total_render(filename)
    respond_to do |format|
      format.html { render template: "spree/admin/reports/total_base" }
      format.csv do
        send_data @report.ruportdata.to_csv
      end
    end
  end  

  def units
    @report = Spree::AdvancedReport::IncrementReport::Units.new(params)
    base_report_render("units")
  end

  def total_digitals
    @report = Spree::AdvancedReport::TotalReport::TotalDigitals.new(params)
    base_report_total_render("total_digitals")
  end

  def total_products
    @report = Spree::AdvancedReport::TotalReport::TotalProducts.new(params)
    base_report_total_render("total_products")
  end

  def total_payment_methods
    @report = Spree::AdvancedReport::TotalReport::TotalPaymentMethods.new(params)
    base_report_total_render("total_payment_methods")
  end

  def base_report_top_render(filename)
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/top_base" }
      format.csv do
        send_data @report.ruportdata.to_csv
      end
    end
  end

  def geo_report_render(filename)
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]["report_type"] = params[:advanced_reporting]["report_type"].to_sym if params[:advanced_reporting]["report_type"]
    params[:advanced_reporting]["report_type"] ||= :state
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/geo_base" }
      format.csv do
        send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv
      end
    end
  end

  def revenue
    @report = Spree::AdvancedReport::IncrementReport::Revenue.new(params)
    base_report_render("revenue")
  end

  def profit
    @report = Spree::AdvancedReport::IncrementReport::Profit.new(params)
    base_report_render("profit")
  end

  def count
    @report = Spree::AdvancedReport::IncrementReport::Count.new(params)
    base_report_render("profit")
  end

  def top_products
    @report = Spree::AdvancedReport::TopReport::TopProducts.new(params, 10)
    base_report_top_render("top_products")
  end

  def top_customers
    @report = Spree::AdvancedReport::TopReport::TopCustomers.new(params, 4)
    base_report_top_render("top_customers")
  end

  def geo_revenue
    @report = Spree::AdvancedReport::GeoReport::GeoRevenue.new(params)
    geo_report_render("geo_revenue")
  end

  def geo_units
    @report = Spree::AdvancedReport::GeoReport::GeoUnits.new(params)
    geo_report_render("geo_units")
  end

  def geo_profit
    @report = Spree::AdvancedReport::GeoReport::GeoProfit.new(params)
    geo_report_render("geo_profit")
  end

  private
  def set_locale
    I18n.locale ||= I18n.default_locale
  end

end

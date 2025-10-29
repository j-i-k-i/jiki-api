class Concept::Search
  include Mandate

  DEFAULT_PAGE = 1
  DEFAULT_PER = 24

  def self.default_per
    DEFAULT_PER
  end

  def initialize(title: nil, page: nil, per: nil)
    @title = title
    @page = page.present? && page.to_i.positive? ? page.to_i : DEFAULT_PAGE
    @per = per.present? && per.to_i.positive? ? per.to_i : self.class.default_per
  end

  def call
    @collection = Concept.all

    apply_title_filter!

    @collection.page(page).per(per)
  end

  private
  attr_reader :title, :page, :per

  def apply_title_filter!
    return if title.blank?

    @collection = @collection.where("title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(title)}%")
  end
end

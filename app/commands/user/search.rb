class User::Search
  include Mandate

  DEFAULT_PAGE = 1
  DEFAULT_PER = 24

  def self.default_per
    DEFAULT_PER
  end

  def initialize(name: nil, email: nil, page: nil, per: nil)
    @name = name
    @email = email
    @page = page.present? && page.to_i.positive? ? page.to_i : DEFAULT_PAGE
    @per = per.present? && per.to_i.positive? ? per.to_i : self.class.default_per
  end

  def call
    @users = User.all

    filter_name!
    filter_email!

    @users.page(page).per(per)
  end

  private
  attr_reader :name, :email, :page, :per

  def filter_name!
    return if name.blank?

    @users = @users.where("name LIKE ?", "%#{name}%")
  end

  def filter_email!
    return if email.blank?

    @users = @users.where("email LIKE ?", "%#{email}%")
  end
end

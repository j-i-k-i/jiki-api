class UserDrop < Liquid::Drop
  # rubocop:disable Lint/MissingSuper
  def initialize(user)
    @user = user
  end
  # rubocop:enable Lint/MissingSuper

  delegate :name, :email, :locale, to: :@user
end

class UserDrop < Liquid::Drop
  # rubocop:disable Lint/MissingSuper
  def initialize(user)
    @user = user
  end
  # rubocop:enable Lint/MissingSuper

  delegate :name, to: :@user

  delegate :email, to: :@user

  delegate :locale, to: :@user
end

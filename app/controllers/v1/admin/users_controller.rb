class V1::Admin::UsersController < V1::Admin::BaseController
  def index
    users = User::Search.(
      name: params[:name],
      email: params[:email],
      page: params[:page],
      per: params[:per]
    )

    render json: SerializePaginatedCollection.(
      users,
      serializer: SerializeAdminUsers
    )
  end
end

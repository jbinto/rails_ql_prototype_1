class QueriesController < ApplicationController
  around_action :handle_railsql_exceptions

  def create
    ctx = {current_user: current_user}
    root = RailsQL::Runner.new(Schema).execute!(
      ctx: ctx,
      query: params[:query]
    )
    render json: Oj.dump(root.as_json)
  end

  def handle_railsql_exceptions
    yield
  rescue RailsQL::UnauthorizedQuery, RailsQL::UnauthorizedMutation => e
    if Rails.env.development?
      render json: {error: e.message}, status: 403
    else
      render nothing: true, status: 403
    end
  end

  def current_user
    # In a real application we would not allow the user to set their user id
    # with params because it would be a security vulnerability - any user
    # could claim to be any other user they wanted to steal the account of.
    #
    # In a real application replace the next line with:
    # User.find session[:current_user_id]
    User.find params[:current_user_id]
  end

end

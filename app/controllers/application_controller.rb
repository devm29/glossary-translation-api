class ApplicationController < ActionController::API
  # Error handling lives here so every endpoint returns the same JSON shape for
  # the same class of failure, and so controller actions can use `find` and
  # `params.expect` without defensive branching.
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_malformed_body
  rescue_from Highlighting::Markup::Unknown, with: :render_unprocessable
  # Two concurrent creates of the same language pair both pass the uniqueness
  # validation; the unique index stops the second, and it should read as a
  # conflict rather than a 500.
  rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

  private

  # `exception.model` is the class name Rails was looking for, which gives
  # "Glossary not found" / "Translation not found" without repeating the string
  # in each controller.
  def render_not_found(exception)
    render json: {errors: "#{exception.model || "Record"} not found"}, status: :not_found
  end

  def render_parameter_missing(exception)
    render json: {errors: "Required parameter missing: #{exception.param}"}, status: :bad_request
  end

  def render_malformed_body(_exception)
    render json: {errors: "Request body is not valid JSON"}, status: :bad_request
  end

  def render_conflict(_exception)
    render json: {errors: "A record with the same unique attributes already exists"}, status: :conflict
  end

  def render_unprocessable(exception)
    render json: {errors: exception.message}, status: :unprocessable_content
  end
end

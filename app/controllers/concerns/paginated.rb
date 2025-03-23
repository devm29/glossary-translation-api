# Keeps index endpoints bounded.
#
# Collections are returned as a plain JSON array — the shape clients already
# depend on — and the paging metadata travels in response headers, so adding
# pagination did not change any existing response body.
module Paginated
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  # Past this the OFFSET no longer fits in a database integer; every page
  # beyond the data is empty anyway.
  MAX_PAGE = 1_000_000

  private

  # @param scope [ActiveRecord::Relation]
  # @return [ActiveRecord::Relation] limited to the requested page
  def paginate(scope)
    total = scope.count(:all)
    total_pages = [(total.to_f / per_page).ceil, 1].max

    response.set_header("X-Page", current_page.to_s)
    response.set_header("X-Per-Page", per_page.to_s)
    response.set_header("X-Total-Count", total.to_s)
    response.set_header("X-Total-Pages", total_pages.to_s)

    scope.limit(per_page).offset((current_page - 1) * per_page)
  end

  def current_page
    @current_page ||= positive_integer_param(:page)&.clamp(1, MAX_PAGE) || 1
  end

  def per_page
    @per_page ||= positive_integer_param(:per_page)&.clamp(1, MAX_PER_PAGE) || DEFAULT_PER_PAGE
  end

  # A query string can carry an array or a hash (`?page[]=2`), which has no
  # `to_i`; anything other than a positive integer string counts as absent.
  def positive_integer_param(name)
    value = params[name]
    number = value.is_a?(String) ? value.to_i : 0
    number if number.positive?
  end
end

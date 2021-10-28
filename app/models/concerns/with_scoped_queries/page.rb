module WithScopedQueries::Page
  def self.query_by(params, current_scope, _)
    if params[:limit].present?
      current_scope
    else
      page_param = params[:page] || 1
      current_scope.page(page_param).per(10)
    end
  end

  def self.add_queriable_attributes_to(klass, _)
    klass.queriable_attributes.merge!(page: [:page, :limit])
  end
end

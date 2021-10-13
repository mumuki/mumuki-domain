module WithScopedQueries::Limit
  def self.query_by(params, current_scope, _)
    if params[:limit].present?
      max_limit = [params[:limit].to_i, 25].min
      current_scope.limit(max_limit)
    else
      current_scope
    end
  end

  def self.add_queriable_attributes_to(klass, _)
    klass.queriable_attributes.merge!(limit: :limit)
  end
end

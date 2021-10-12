module WithScopedQueries::Limit
  def self.query_by(params, current_scope, _)
    if params[:limit].present?
      current_scope.limit(params[:limit])
    else
      current_scope
    end
  end

  def self.add_queriable_attributes_to(klass, _)
    klass.queriable_attributes.merge!(limit: :limit)
  end
end

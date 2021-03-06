class InteractionSearchResultsApiPresenter
  def initialize(search_results)
    @search_results = search_results
  end

  def matched_results
    @matched_results ||= @search_results
      .select { |r| r.is_definite? && r.has_interactions? }
      .map { |r| InteractionSearchResultApiPresenter.new(r) }
  end

  def unmatched_results
    @unmatched_results ||= @search_results
      .select { |r| r.is_ambiguous? || !r.has_results? }
  end

end

module Contextualization
  extend ActiveSupport::Concern

  class_methods do

    private

    def submission_mapping
      class_attrs = Mumuki::Domain::Submission::Base.mapping_attributes.map { |it| submission_fields_overrides[it] || it }
      class_attrs.zip Mumuki::Domain::Submission::Base.mapping_attributes
    end

    def submission_fields_overrides
      { status: :submission_status }
    end
  end

  included do
    serialize :submission_status, Mumuki::Domain::Status::Submission
    validates_presence_of :submission_status

    serialize_symbolized_hash_array :expectation_results, :test_results, :query_results

    composed_of :submission, mapping: submission_mapping, constructor: :from_attributes, class_name: 'Mumuki::Domain::Submission::Base'

    delegate :visible_success_output?, to: :exercise
    delegate :output_content_type, to: :language
    delegate :should_retry?, :to_submission_status, :completed?, :solved?, *Mumuki::Domain::Status::Submission.test_selectors, to: :submission_status
    delegate :inspection_keywords, to: :exercise
  end

  def queries_with_results
    queries.zip(query_results).map do |query, result|
      {query: query, status: result&.dig(:status).defaulting(:pending), result: result&.dig(:result)}
    end
  end

  # deprecated: this method does hidden assumptions about the UI not wanting
  # non-empty titles to not be displayed. Also it incorrectly uses the term `visual` instead of `visible`
  def single_visual_result?
    warn 'use single_visible_test_result? instead'
    single_visible_test_result? && first_test_result[:title].blank?
  end

  # deprecated: this method does not validate nor depends on any `visible` condition
  # Also, it incorrectly uses the term `visual` instead of `visible`
  def single_visual_result_html
    warn 'use first_test_result_html intead'
    first_test_result_html
  end

  def single_visible_test_result?
    test_results.size == 1 && visible_success_output?
  end

  def first_test_result
    test_results.first
  end

  def first_test_result_html
    test_result_html first_test_result
  end

  def test_result_html(test_result)
    output_content_type.to_html test_result[:result]
  end

  def results_body_hidden?
    (passed? && !visible_success_output?) || exercise.choice? || manual_evaluation_pending? || skipped?
  end

  def visible_status
    status
  end

  def iconize
    visible_status.iconize
  end

  def result_html
    output_content_type.to_html(result)
  end

  def feedback_html
    output_content_type.to_html(feedback)
  end

  def failed_expectation_results
    expectation_results.to_a.select { |it| it[:result].failed? }.uniq
  end

  def expectation_results_visible?
    failed_expectation_results.present?
  end

  def visible_expectation_results
    exercise.input_kids? ? failed_expectation_results.first(1) : failed_expectation_results
  end

  def humanized_expectation_results
    warn "Don't use humanized_expectation_results. Use affable_expectation_results, which also handles markdown an sanitization"
    visible_expectation_results.map do |it|
      {
        result: it[:result],
        explanation: Mulang::Expectation.parse(it).translate(inspection_keywords)
      }
    end
  end

  ####################
  ## Affable results
  ####################

  def affable_expectation_results
    visible_expectation_results.map do |it|
      {
        result: it[:result],
        explanation: Mulang::Expectation.parse(it).translate(inspection_keywords).affable
      }
    end
  end

  def affable_tips
    tips.map(&:affable)
  end

  def affable_test_results
    test_results.to_a.map do |it|
      { summary: it.dig(:summary, :message).affable }
        .compact
        .merge(
          title: it[:title].affable,
          result: it[:result].sanitized,
          status: it[:status])
    end
  end
end

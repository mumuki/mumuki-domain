class Mumuki::Domain::Submission::Base
  include ActiveModel::Model

  required :try_evaluate!

  demodulized_model_name

  ATTRIBUTES = [:solution, :status, :result, :expectation_results, :feedback, :test_results,
                :submission_id, :queries, :query_results, :manual_evaluation_comment]

  attr_accessor *ATTRIBUTES
  attr_accessor :client_result

  def self.from_attributes(*args)
    new ATTRIBUTES.zip(args).to_h
  end

  def self.mapping_attributes
    ATTRIBUTES
  end

  def run!(assignment, evaluation)
    save_submission! assignment
    results = dry_run! assignment, evaluation
    save_results! results, assignment
    notify_results! results, assignment
    results
  end

  # By default evaluation strategy is ignored.
  # Subclasses may override this behaviour
  def dry_run!(assignment, _evaluation)
    evaluate! assignment
  end

  def with_client_result(result)
    self.client_result = result if result.present?
    self
  end

  def evaluate!(assignment)
    try_evaluate! assignment
  rescue => e
    Rails.logger.error "Evaluation failed: #{e} \n#{e.backtrace.join("\n")}"
    {status: :errored, result: e.message}
  end

  def id
    @id ||= SecureRandom.hex(8)
  end

  private

  def save_submission!(assignment)
    assignment.content = content
    assignment.recontextualize!
    assignment.save!
  end

  def save_results!(results, assignment)
    assignment.assign_attributes results
    assignment.increment_attempts!
    assignment.save! results
  end

  def notify_results!(results, assignment)
    assignment.notify!
  end
end

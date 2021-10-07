module WithMessages
  def receive_answer!(answer)
    build_message(answer).save!
  end

  def send_question!(question)
    message = build_message question.merge(sender: submitter, read: true)
    message.save_and_notify!
  end

  def build_message(body)
    messages.build({date: Time.current, submission_id: submission_id}.merge(body))
  end

  def has_messages?
    messages.exists?
  end

  def pending_messages?
    messages.exists? read: false
  end
end

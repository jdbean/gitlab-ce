# frozen_string_literal: true
module Emails
  module AutoDevops
    def autodevops_disabled_email(pipeline, recipient)
      @pipeline = pipeline
      @project = pipeline.project

      mail(to: recipient,
           subject: "Auto DevOps pipeline was disabled for #{@project.name}") do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end
  end
end

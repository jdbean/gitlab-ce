# frozen_string_literal: true

module AutoDevops
  class DisableWorker
    include ApplicationWorker
    include AutoDevopsQueue

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find(pipeline_id)
      project = pipeline.project

      send_notification_email(pipeline, project) if disable_service(project).execute
    end

    private

    def disable_service(project)
      Projects::AutoDevops::DisableService.new(project)
    end

    def send_notification_email(pipeline, project)
      recipients = [pipeline.user, project.owner].uniq.compact.map(&:email)

      NotificationService.new.autodevops_disabled(pipeline, recipients)
    end
  end
end

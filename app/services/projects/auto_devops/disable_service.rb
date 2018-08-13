# frozen_string_literal: true

module Projects
  module AutoDevops
    class DisableService < BaseService
      def execute
        return false unless project.has_auto_devops_implicitly_enabled?

        project.auto_devops.update_attribute(:enabled, false)
      end
    end
  end
end

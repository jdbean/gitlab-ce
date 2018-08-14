# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module CommandResources
        def create_resources(kubeclient)
          # no-op by default
        end
      end
    end
  end
end

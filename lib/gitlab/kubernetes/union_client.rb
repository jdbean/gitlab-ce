# frozen_string_literal: true

module Gitlab
  module Kubernetes
    # Wrapper around Kubeclient::Client to dispatch
    # the right message to the client that can respond to the message.
    # We must have a kubeclient for each ApiGroup as there is no
    # other way to use the Kubeclient gem.
    #
    # See https://github.com/abonas/kubeclient/issues/348.
    class UnionClient
      attr_reader :kubeclient, :kubeclient_rbac

      # Arguments are Kubeclient::Client objects where:
      # - kubeclient must be able to process the core api, ie. /api
      # - kubeclient_rbac must be able to process the rbac.authorization.k8s.io api group ie. /apis/rbac.authorization.k8s.io
      def initialize(kubeclient, kubeclient_rbac)
        @kubeclient = kubeclient
        @kubeclient_rbac = kubeclient_rbac
      end

      def method_missing(method, *args, &block)
        kubeclient.public_send(method, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end

      def create_cluster_role_binding(*args)
        kubeclient_rbac.create_cluster_role_binding(*args)
      end
    end
  end
end

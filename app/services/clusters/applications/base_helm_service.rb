# frozen_string_literal: true

module Clusters
  module Applications
    class BaseHelmService
      attr_accessor :app

      def initialize(app)
        @app = app
      end

      protected

      def cluster
        app.cluster
      end

      def kubeclient
        cluster.kubeclient
      end

      def union_client
        cluster.kubeclient_union
      end

      def helm_api
        @helm_api ||= Gitlab::Kubernetes::Helm::Api.new(union_client)
      end

      def install_command
        @install_command ||= app.install_command
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ServiceAccount
      attr_reader :name, :namespace_name, :client

      def initialize(name, namespace_name, client)
        @name = name
        @namespace_name = namespace_name
        @client = client
      end

      def create!
        resource = ::Kubeclient::Resource.new(metadata: metadata)

        client.create_service_account(resource)
      end

      def exists?
        client.get_service_account(name, namespace_name)
      rescue ::Kubeclient::HttpError => ke
        raise ke unless ke.error_code == 404

        false
      end

      def ensure_exists!
        exists? || create!
      end

      private

      def metadata
        {
          name: name,
          namespace: namespace_name
        }
      end
    end
  end
end

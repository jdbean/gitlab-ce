module Gitlab
  module Kubernetes
    module Helm
      class InitCommand
        extend ::Gitlab::Utils::Override

        include BaseCommand
        include CommandResources

        attr_reader :name, :files, :service_account_name

        def initialize(name:, files:, service_account_name: nil)
          @name = name
          @files = files
          @service_account_name = service_account_name
        end

        def generate_script
          super + [
            init_helm_command
          ].join("\n")
        end

        override :create_resources
        def create_resources(kubeclient)
          if service_account_name
            kubeclient.create_service_account(service_account_resource)
            kubeclient.create_cluster_role_binding(cluster_role_binding_resource)
          end
        end

        private

        def init_helm_command
          tls_flags = "--tiller-tls" \
            " --tiller-tls-verify --tls-ca-cert #{files_dir}/ca.pem" \
            " --tiller-tls-cert #{files_dir}/cert.pem" \
            " --tiller-tls-key #{files_dir}/key.pem"

          "helm init #{tls_flags}#{optional_service_account_flag} >/dev/null"
        end

        def optional_service_account_flag
          " --service-account #{service_account_name}" if service_account_name
        end

        def service_account_resource
          Gitlab::Kubernetes::ServiceAccount.new(service_account_name, namespace).generate
        end

        def cluster_role_binding_resource
          subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: namespace }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            Gitlab::Kubernetes::Helm::CLUSTER_ROLE_BINDING,
            Gitlab::Kubernetes::Helm::CLUSTER_ROLE,
            subjects
          ).generate
        end
      end
    end
  end
end

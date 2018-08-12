module Gitlab
  module Kubernetes
    module Helm
      class InitCommand
        include BaseCommand

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
      end
    end
  end
end

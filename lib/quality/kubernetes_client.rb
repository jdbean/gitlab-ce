# frozen_string_literal: true

require_relative '../gitlab/popen'

module Quality
  class KubernetesClient
    attr_reader :namespace

    def initialize(namespace: ENV['KUBE_NAMESPACE'])
      @namespace = namespace
    end

    def cleanup(release_name:)
      command = [%(-n "#{namespace}" get ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa 2>&1)]
      command << '|' << %(grep "#{release_name}")
      command << '|' << "awk '{print $1}'"
      command << '|' << %(xargs kubectl -n "#{namespace}" delete)
      command << '||' << 'true'

      run_command(command)
    end

    private

    def run_command(command)
      final_command = ['kubectl', *command].join(' ')
      puts "Running command: `#{final_command}`" # rubocop:disable Rails/Output

      Gitlab::Popen.popen_with_detail([final_command])
    end
  end
end

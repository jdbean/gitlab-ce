require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:commands) { 'helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem >/dev/null' }

  subject { described_class.new(name: application.name, files: {}) }

  it_behaves_like 'helm commands'

  context 'when there is a service account' do
    subject { described_class.new(name: application.name, files: {}, service_account_name: 'tiller') }

    it_behaves_like 'helm commands' do
      let(:commands) { 'helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem --service-account tiller >/dev/null' }
    end
  end

  describe '#create_resources' do
    let(:kubeclient) { double('kubeclient') }
    let(:command) { described_class.new(name: application.name, files: {}, service_account_name: service_account_name) }

    let(:service_account_resource) do
      Kubeclient::Resource.new(metadata: { name: 'helm-service-account', namespace: 'gitlab-managed-apps' })
    end

    let(:cluster_role_binding_resource) do
      Kubeclient::Resource.new(
        metadata: { name: 'tiller-admin' },
        roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
        subjects: [{ kind: 'ServiceAccount', name: 'helm-service-account', namespace: 'gitlab-managed-apps' }]
      )
    end

    context 'no service_account_name' do
      let(:service_account_name) { nil }

      it 'does a no-op' do
        expect(kubeclient).not_to receive(:create_service_account)
        expect(kubeclient).not_to receive(:create_cluster_role_binding)

        command.create_resources(kubeclient)
      end
    end

    context 'with service_account_name' do
      let(:service_account_name) { 'helm-service-account' }

      it 'creates service account' do
        expect(kubeclient).to receive(:create_service_account).with(service_account_resource).once
        expect(kubeclient).to receive(:create_cluster_role_binding).with(cluster_role_binding_resource).once

        command.create_resources(kubeclient)
      end
    end
  end
end

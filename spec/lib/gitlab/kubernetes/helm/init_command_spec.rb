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
end

# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::UnionClient do
  let(:kubeclient) { double('kubeclient') }
  let(:kubeclient_rbac) { double('kubeclient rbac') }

  let(:client) { described_class.new(kubeclient, kubeclient_rbac) }

  describe '#create_cluster_role_binding' do
    it 'delegates to kubeclient_rbac' do
      expect(kubeclient_rbac).to receive(:create_cluster_role_binding).with({})

      client.create_cluster_role_binding({})
    end
  end

  describe 'core api methods' do
    it 'deletgates to kubeclient' do
      expect(kubeclient).to receive(:create_pod).with({})

      client.create_pod({})
    end
  end
end

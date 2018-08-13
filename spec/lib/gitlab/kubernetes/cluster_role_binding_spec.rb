# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::ClusterRoleBinding do
  let(:name) { 'cluster-role-binding-name' }
  let(:cluster_role_name) { 'cluster-admin' }
  let(:subjects) { [{ kind: 'ServiceAccount', name: 'sa', namespace: 'ns' }] }
  let(:clusterrolebinding) { described_class.new(name, cluster_role_name, subjects) }

  describe '#generate' do
    let(:roleref) { { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: cluster_role_name } }
    let(:resource) { ::Kubeclient::Resource.new(metadata: { name: name }, roleRef: roleref, subjects: subjects) }

    subject { clusterrolebinding.generate }

    it 'should build a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end

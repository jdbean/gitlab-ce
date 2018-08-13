# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::ServiceAccount do
  let(:name) { 'a_service_account' }
  let(:namespace_name) { 'a_namespace' }
  let(:client) { double('kubernetes client') }
  subject { described_class.new(name, namespace_name, client) }

  it { expect(subject.name).to eq(name) }
  it { expect(subject.namespace_name).to eq(namespace_name) }

  describe '#create!' do
    it 'creates a serviceAccount' do
      matcher = have_attributes(metadata: have_attributes(name: name, namespace: namespace_name))
      expect(client).to receive(:create_service_account).with(matcher).once

      expect { subject.create! }.not_to raise_error
    end
  end

  describe '#exists?' do
    context 'when namespace do not exits' do
      let(:exception) { ::Kubeclient::HttpError.new(404, "serviceaccounts #{name} not found", nil) }

      it 'returns false' do
        expect(client).to receive(:get_service_account).with(name, namespace_name).once.and_raise(exception)

        expect(subject.exists?).to be_falsey
      end
    end

    context 'when namespace exits' do
      let(:serviceaccount) { ::Kubeclient::Resource.new(kind: 'Namespace', metadata: { name: name, namespace: namespace_name }) } # partial representation

      it 'returns true' do
        expect(client).to receive(:get_service_account).with(name, namespace_name).once.and_return(serviceaccount)

        expect(subject.exists?).to be_truthy
      end
    end

    context 'when cluster cannot be reached' do
      let(:exception) { Errno::ECONNREFUSED.new }

      it 'raises exception' do
        expect(client).to receive(:get_service_account).with(name, namespace_name).once.and_raise(exception)

        expect { subject.exists? }.to raise_error(exception)
      end
    end
  end

  describe '#ensure_exists!' do
    it 'checks for existing serviceaccount before creating' do
      expect(subject).to receive(:exists?).once.ordered.and_return(false)
      expect(subject).to receive(:create!).once.ordered

      subject.ensure_exists!
    end

    it 'do not re-create an existing serviceaccount' do
      expect(subject).to receive(:exists?).once.and_return(true)
      expect(subject).not_to receive(:create!)

      subject.ensure_exists!
    end
  end
end

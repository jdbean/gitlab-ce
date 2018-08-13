# frozen_string_literal: true
require 'spec_helper'

describe Projects::AutoDevops::DisableService, '#execute' do
  let(:project) { create(:project, :repository, :auto_devops) }
  let(:auto_devops) { project.auto_devops }

  subject { described_class.new(project).execute }

  context 'when auto devops disabled on settings' do
    before do
      stub_application_setting(auto_devops_enabled: false)
    end

    it { is_expected.to be_falsy }
  end

  context 'when auto devops enabled on settings' do
    before do
      stub_application_setting(auto_devops_enabled: true)
    end

    context 'when auto devops explicitly enabled on project' do
      before do
        auto_devops.update_attribute(:enabled, true)
      end

      it { is_expected.to be_falsy }
    end

    context 'when auto devops explicitly disabled on project' do
      before do
        auto_devops.update_attribute(:enabled, false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when auto devops defaults to instance' do
      before do
        auto_devops.update_attribute(:enabled, nil)

        subject
      end

      it { is_expected.to be_truthy }

      it 'should disable auto devops for project' do
        expect(auto_devops.enabled?).to be_falsy
      end
    end
  end
end

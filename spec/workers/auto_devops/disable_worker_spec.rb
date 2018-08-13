# frozen_string_literal: true
require 'spec_helper'

describe AutoDevops::DisableWorker, '#perform' do
  let(:project) { create(:project, :repository, :auto_devops) }
  let(:auto_devops) { project.auto_devops }
  let(:pipeline) { create(:ci_pipeline, :failed, project: project) }

  subject { described_class.new }

  before do
    stub_application_setting(auto_devops_enabled: true)
    auto_devops.update_attribute(:enabled, nil)
  end

  it 'disables autodevops for project' do
    subject.perform(pipeline.id)

    expect(auto_devops.reload.enabled).not_to be_nil
    expect(auto_devops.reload.enabled?).to be_falsy
  end

  it 'calls Notification Service class' do
    expect(NotificationService).to receive_message_chain(:new, :autodevops_disabled)

    subject.perform(pipeline.id)
  end
end

require 'spec_helper'

describe Mattermost::SlashCommandService, service: true do
  let(:project)         { build(:project) }
  let(:user)            { build(:user) }
  let(:params)          { { text: 'issue show 1' } }

  subject { described_class.new(project, user, params).execute }

  describe '#execute' do
    context 'no command service is triggered' do
      let(:params) { { text: 'unknown_command' } }

      it 'shows the help messages' do
        expect(subject[:response_type]).to be :ephemeral
        expect(subject[:text]).to start_with 'Sadly, the used command'
      end
    end

    context 'a valid command is executed' do
      let(:issue)   { create(:issue, project: project) }
      let(:params)  { { text: "issue show #{issue.iid}" } }

      it 'a resource is presented to the user' do
        expect(subject[:response_type]).to be :in_channel
        expect(subject[:text]).to match issue.title
      end
    end
  end
end

require 'spec_helper'

describe MergeRequests::BuildService do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:source_project) { nil }
  let(:target_project) { nil }
  let(:user) { create(:user) }
  let(:issue_confidential) { false }
  let(:issue) { create(:issue, project: project, title: 'A bug', confidential: issue_confidential) }
  let(:description) { nil }
  let(:source_branch) { 'feature-branch' }
  let(:target_branch) { 'master' }
  let(:merge_request) { service.execute }
  let(:compare) { double(:compare, commits: commits) }
  let(:commit_1) { double(:commit_1, safe_message: "Initial commit\n\nCreate the app") }
  let(:commit_2) { double(:commit_2, safe_message: 'This is a bad commit message!') }
  let(:commits) { nil }

  let(:service) do
    described_class.new(project, user,
                                    description: description,
                                    source_branch: source_branch,
                                    target_branch: target_branch,
                                    source_project: source_project,
                                    target_project: target_project)
  end

  before do
    project.add_guest(user)
  end

  def stub_compare
    allow(CompareService).to receive_message_chain(:new, :execute).and_return(compare)
    allow(project).to receive(:commit).and_return(commit_1)
    allow(project).to receive(:commit).and_return(commit_2)
  end

  describe '#execute' do
    it 'calls the compare service with the correct arguments' do
      allow_any_instance_of(described_class).to receive(:branches_valid?).and_return(true)
      expect(CompareService).to receive(:new)
                                  .with(project, Gitlab::Git::BRANCH_REF_PREFIX + source_branch)
                                  .and_call_original

      expect_any_instance_of(CompareService).to receive(:execute)
                                                  .with(project, Gitlab::Git::BRANCH_REF_PREFIX + target_branch)
                                                  .and_call_original

      merge_request
    end

    context 'missing source branch' do
      let(:source_branch) { '' }

      it 'forbids the merge request from being created' do
        expect(merge_request.can_be_created).to eq(false)
      end

      it 'adds an error message to the merge request' do
        expect(merge_request.errors).to contain_exactly('You must select source and target branch')
      end
    end

    context 'when target branch is missing' do
      let(:target_branch) { nil }
      let(:commits) { Commit.decorate([commit_1], project) }

      before do
        stub_compare
      end

      it 'creates compare object with target branch as default branch' do
        expect(merge_request.compare).to be_present
        expect(merge_request.target_branch).to eq(project.default_branch)
      end

      it 'allows the merge request to be created' do
        expect(merge_request.can_be_created).to eq(true)
      end
    end

    context 'same source and target branch' do
      let(:source_branch) { 'master' }

      it 'forbids the merge request from being created' do
        expect(merge_request.can_be_created).to eq(false)
      end

      it 'adds an error message to the merge request' do
        expect(merge_request.errors).to contain_exactly('You must select different branches')
      end
    end

    context 'no commits in the diff' do
      let(:commits) { [] }

      before do
        stub_compare
      end

      it 'allows the merge request to be created' do
        expect(merge_request.can_be_created).to eq(true)
      end

      it 'adds a WIP prefix to the merge request title' do
        expect(merge_request.title).to eq('WIP: Feature branch')
      end
    end

    context 'one commit in the diff' do
      let(:commits) { Commit.decorate([commit_1], project) }

      before do
        stub_compare
      end

      it 'allows the merge request to be created' do
        expect(merge_request.can_be_created).to eq(true)
      end

      it 'uses the title of the commit as the title of the merge request' do
        expect(merge_request.title).to eq(commit_1.safe_message.split("\n").first)
      end

      it 'uses the description of the commit as the description of the merge request' do
        expect(merge_request.description).to eq(commit_1.safe_message.split(/\n+/, 2).last)
      end

      context 'merge request already has a description set' do
        let(:description) { 'Merge request description' }

        it 'keeps the description from the initial params' do
          expect(merge_request.description).to eq(description)
        end
      end

      context 'commit has no description' do
        let(:commits) { Commit.decorate([commit_2], project) }

        it 'uses the title of the commit as the title of the merge request' do
          expect(merge_request.title).to eq(commit_2.safe_message)
        end

        it 'sets the description to nil' do
          expect(merge_request.description).to be_nil
        end
      end

      context 'branch starts with issue IID followed by a hyphen' do
        let(:source_branch) { "#{issue.iid}-fix-issue" }

        it 'appends "Closes #$issue-iid" to the description' do
          expect(merge_request.description).to eq("#{commit_1.safe_message.split(/\n+/, 2).last}\n\nCloses ##{issue.iid}")
        end

        context 'merge request already has a description set' do
          let(:description) { 'Merge request description' }

          it 'appends "Closes #$issue-iid" to the description' do
            expect(merge_request.description).to eq("#{description}\n\nCloses ##{issue.iid}")
          end
        end

        context 'commit has no description' do
          let(:commits) { Commit.decorate([commit_2], project) }

          it 'sets the description to "Closes #$issue-iid"' do
            expect(merge_request.description).to eq("Closes ##{issue.iid}")
          end
        end
      end

      context 'branch starts with numeric characters followed by a hyphen with no issue tracker' do
        let(:source_branch) { '12345-fix-issue' }

        before do
          allow(project).to receive(:external_issue_tracker).and_return(false)
          allow(project).to receive(:issues_enabled?).and_return(false)
        end

        it 'uses the title of the commit as the title of the merge request' do
          expect(merge_request.title).to eq(commit_1.safe_message.split("\n").first)
        end

        it 'uses the description of the commit as the description of the merge request' do
          commit_description = commit_1.safe_message.split(/\n+/, 2).last

          expect(merge_request.description).to eq("#{commit_description}")
        end
      end

      context 'branch starts with JIRA-formatted external issue IID followed by a hyphen' do
        let(:source_branch) { 'EXMPL-12345-fix-issue' }

        before do
          allow(project).to receive(:external_issue_tracker).and_return(true)
          allow(project).to receive(:issues_enabled?).and_return(false)
          allow(project).to receive(:external_issue_reference_pattern).and_return(IssueTrackerService.reference_pattern)
        end

        it 'uses the title of the commit as the title of the merge request' do
          expect(merge_request.title).to eq(commit_1.safe_message.split("\n").first)
        end

        it 'uses the description of the commit as the description of the merge request and appends the closes text' do
          commit_description = commit_1.safe_message.split(/\n+/, 2).last

          expect(merge_request.description).to eq("#{commit_description}\n\nCloses EXMPL-12345")
        end
      end
    end

    context 'more than one commit in the diff' do
      let(:commits) { Commit.decorate([commit_1, commit_2], project) }

      before do
        stub_compare
      end

      it 'allows the merge request to be created' do
        expect(merge_request.can_be_created).to eq(true)
      end

      it 'uses the title of the branch as the merge request title' do
        expect(merge_request.title).to eq('Feature branch')
      end

      it 'does not add a description' do
        expect(merge_request.description).to be_nil
      end

      context 'merge request already has a description set' do
        let(:description) { 'Merge request description' }

        it 'keeps the description from the initial params' do
          expect(merge_request.description).to eq(description)
        end
      end

      context 'branch starts with GitLab issue IID followed by a hyphen' do
        let(:source_branch) { "#{issue.iid}-fix-issue" }

        it 'sets the title to: Resolves "$issue-title"' do
          expect(merge_request.title).to eq("Resolve \"#{issue.title}\"")
        end

        context 'when issue is not accessible to user' do
          before do
            project.team.truncate
          end

          it 'uses branch title as the merge request title' do
            expect(merge_request.title).to eq("#{issue.iid} fix issue")
          end
        end

        context 'issue does not exist' do
          let(:source_branch) { "#{issue.iid.succ}-fix-issue" }

          it 'uses the title of the branch as the merge request title' do
            expect(merge_request.title).to eq("#{issue.iid.succ} fix issue")
          end
        end

        context 'issue is confidential' do
          let(:issue_confidential) { true }

          it 'uses the title of the branch as the merge request title' do
            expect(merge_request.title).to eq("#{issue.iid} fix issue")
          end
        end
      end

      context 'branch starts with numeric characters followed by a hyphen with no issue tracker' do
        let(:source_branch) { '12345-fix-issue' }

        before do
          allow(project).to receive(:external_issue_tracker).and_return(false)
          allow(project).to receive(:issues_enabled?).and_return(false)
        end

        it 'sets the title to the humanized branch title' do
          expect(merge_request.title).to eq('12345 fix issue')
        end
      end

      context 'branch starts with JIRA-formatted external issue IID' do
        let(:source_branch) { 'EXMPL-12345' }

        before do
          allow(project).to receive(:external_issue_tracker).and_return(true)
          allow(project).to receive(:issues_enabled?).and_return(false)
          allow(project).to receive(:external_issue_reference_pattern).and_return(IssueTrackerService.reference_pattern)
        end

        it 'sets the title to the humanized branch title' do
          expect(merge_request.title).to eq('Resolve EXMPL-12345')
        end

        it 'appends the closes text' do
          expect(merge_request.description).to eq('Closes EXMPL-12345')
        end

        context 'followed by hyphenated text' do
          let(:source_branch) { 'EXMPL-12345-fix-issue' }

          it 'sets the title to the humanized branch title' do
            expect(merge_request.title).to eq('Resolve EXMPL-12345 "Fix issue"')
          end

          it 'appends the closes text' do
            expect(merge_request.description).to eq('Closes EXMPL-12345')
          end
        end
      end
    end

    context 'source branch does not exist' do
      before do
        allow(project).to receive(:commit).with(source_branch).and_return(nil)
        allow(project).to receive(:commit).with(target_branch).and_return(commit_1)
      end

      it 'forbids the merge request from being created' do
        expect(merge_request.can_be_created).to eq(false)
      end

      it 'adds an error message to the merge request' do
        expect(merge_request.errors).to contain_exactly('Source branch "feature-branch" does not exist')
      end
    end

    context 'target branch does not exist' do
      before do
        allow(project).to receive(:commit).with(source_branch).and_return(commit_1)
        allow(project).to receive(:commit).with(target_branch).and_return(nil)
      end

      it 'forbids the merge request from being created' do
        expect(merge_request.can_be_created).to eq(false)
      end

      it 'adds an error message to the merge request' do
        expect(merge_request.errors).to contain_exactly('Target branch "master" does not exist')
      end
    end

    context 'both source and target branches do not exist' do
      before do
        allow(project).to receive(:commit).and_return(nil)
      end

      it 'forbids the merge request from being created' do
        expect(merge_request.can_be_created).to eq(false)
      end

      it 'adds both error messages to the merge request' do
        expect(merge_request.errors).to contain_exactly(
          'Source branch "feature-branch" does not exist',
          'Target branch "master" does not exist'
        )
      end
    end

    context 'upstream project has disabled merge requests' do
      let(:upstream_project) { create(:project, :merge_requests_disabled) }
      let(:project) { create(:project, forked_from_project: upstream_project) }
      let(:commits) { Commit.decorate([commit_1], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'target_project is set and accessible by current_user' do
      let(:target_project) { create(:project, :public, :repository)}
      let(:commits) { Commit.decorate([commit_1], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(target_project)
      end
    end

    context 'target_project is set but not accessible by current_user' do
      let(:target_project) { create(:project, :private, :repository)}
      let(:commits) { Commit.decorate([commit_1], project) }

      it 'sets target project correctly' do
        expect(merge_request.target_project).to eq(project)
      end
    end

    context 'source_project is set and accessible by current_user' do
      let(:source_project) { create(:project, :public, :repository)}
      let(:commits) { Commit.decorate([commit_1], project) }

      it 'sets target project correctly' do
        expect(merge_request.source_project).to eq(source_project)
      end
    end

    context 'source_project is set but not accessible by current_user' do
      let(:source_project) { create(:project, :private, :repository)}
      let(:commits) { Commit.decorate([commit_1], project) }

      it 'sets target project correctly' do
        expect(merge_request.source_project).to eq(project)
      end
    end
  end
end

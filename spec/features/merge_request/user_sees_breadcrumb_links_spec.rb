require 'rails_helper'

describe 'New merge request breadcrumbs' do
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit project_new_merge_request_path(project)
  end

  it 'displays a link to project issues page' do
    page.within '.breadcrumbs' do
      expect(find_link('Merge Requests')[:href]).to end_with(project_merge_requests_path(project))
    end
  end

  it 'displays a link to new issue page' do
    page.within '.breadcrumbs' do
      expect(find_link('New')[:href]).to end_with(project_new_merge_request_path(project))
    end
  end
end

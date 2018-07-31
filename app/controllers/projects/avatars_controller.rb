class Projects::AvatarsController < Projects::ApplicationController
  include BlobHelper

  before_action :authorize_admin_project!, only: [:destroy]

  def show
    @blob = @repository.blob_at_branch(@repository.root_ref, @project.avatar_in_git)

    if @blob
      send_blob
    else
      render_404
    end
  end

  def destroy
    @project.remove_avatar!

    @project.save

    redirect_to edit_project_path(@project), status: :found
  end
end

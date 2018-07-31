# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include BlobHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)
    if @blob
      send_blob(inline: (params[:inline] != 'false'))
    else
      render_404
    end
  end
end

module Projects
  class UpdatePagesService < BaseService
    BLOCK_SIZE = 32.kilobytes
    MAX_SIZE = 1.terabyte
    SITE_PATH = 'public/'.freeze

    attr_reader :build

    def initialize(project, build)
      @project, @build = project, build
    end

    def execute
      # Create status notifying the deployment of pages
      @status = create_status
      @status.enqueue!
      @status.run!

      raise 'missing pages artifacts' unless build.artifacts?
      raise 'pages are outdated' unless latest?

      # Create temporary directory in which we will extract the artifacts
      FileUtils.mkdir_p(tmp_path)
      Dir.mktmpdir(nil, tmp_path) do |archive_path|
        extract_archive!(archive_path)

        # Check if we did extract public directory
        archive_public_path = File.join(archive_path, 'public')
        raise 'pages miss the public folder' unless Dir.exist?(archive_public_path)
        raise 'pages are outdated' unless latest?

        deploy_page!(archive_public_path)
        success
      end
    rescue => e
      register_failure
      error(e.message)
    ensure
      register_attempt
      build.erase_artifacts! unless build.has_expiring_artifacts?
    end

    private

    def success
      @status.success
      super
    end

    def error(message, http_status = nil)
      log_error("Projects::UpdatePagesService: #{message}")
      @status.allow_failure = !latest?
      @status.description = message
      @status.drop(:script_failure)
      super
    end

    def create_status
      GenericCommitStatus.new(
        project: project,
        pipeline: build.pipeline,
        user: build.user,
        ref: build.ref,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    def extract_archive!(temp_path)
      if artifacts.ends_with?('.tar.gz') || artifacts.ends_with?('.tgz')
        extract_tar_archive!(temp_path)
      elsif artifacts.ends_with?('.zip')
        extract_zip_archive!(temp_path)
      else
        raise 'unsupported artifacts format'
      end
    end

    def extract_tar_archive!(temp_path)
      results = Open3.pipeline(%W(gunzip -c #{artifacts}),
                               %W(dd bs=#{BLOCK_SIZE} count=#{blocks}),
                               %W(tar -x -C #{temp_path} #{SITE_PATH}),
                               err: '/dev/null')
      raise 'pages failed to extract' unless results.compact.all?(&:success?)
    end

    def extract_zip_archive!(temp_path)
      raise 'missing artifacts metadata' unless build.artifacts_metadata?

      # Calculate page size after extract
      public_entry = build.artifacts_metadata_entry(SITE_PATH, recursive: true)

      if public_entry.total_size > max_size
        raise "artifacts for pages are too large: #{public_entry.total_size}"
      end

      # Requires UnZip at least 6.00 Info-ZIP.
      # -qq be (very) quiet
      # -n  never overwrite existing files
      # We add * to end of SITE_PATH, because we want to extract SITE_PATH and all subdirectories
      site_path = File.join(SITE_PATH, '*')
      unless system(*%W(unzip -qq -n #{artifacts} #{site_path} -d #{temp_path}))
        raise 'pages failed to extract'
      end
    end

    def deploy_page!(archive_public_path)
      # Do atomic move of pages
      # Move and removal may not be atomic, but they are significantly faster then extracting and removal
      # 1. We move deployed public to previous public path (file removal is slow)
      # 2. We move temporary public to be deployed public
      # 3. We remove previous public path
      FileUtils.mkdir_p(pages_path)
      begin
        FileUtils.move(public_path, previous_public_path)
      rescue
      end
      FileUtils.move(archive_public_path, public_path)
    ensure
      FileUtils.rm_r(previous_public_path, force: true)
    end

    def latest?
      # check if sha for the ref is still the most recent one
      # this helps in case when multiple deployments happens
      sha == latest_sha
    end

    def blocks
      # Calculate dd parameters: we limit the size of pages
      1 + max_size / BLOCK_SIZE
    end

    def max_size
      max_pages_size = Gitlab::CurrentSettings.max_pages_size.megabytes

      return MAX_SIZE if max_pages_size.zero?

      [max_pages_size, MAX_SIZE].min
    end

    def tmp_path
      @tmp_path ||= File.join(::Settings.pages.path, 'tmp')
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def public_path
      @public_path ||= File.join(pages_path, 'public')
    end

    def previous_public_path
      @previous_public_path ||= File.join(pages_path, "public.#{SecureRandom.hex}")
    end

    def ref
      build.ref
    end

    def artifacts
      build.artifacts_file.path
    end

    def latest_sha
      project.commit(build.ref).try(:sha).to_s
    end

    def sha
      build.sha
    end

    def register_attempt
      pages_deployments_total_counter.increment
    end

    def register_failure
      pages_deployments_failed_total_counter.increment
    end

    def pages_deployments_total_counter
      @pages_deployments_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_total, "Counter of GitLab Pages deployments triggered")
    end

    def pages_deployments_failed_total_counter
      @pages_deployments_failed_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_failed_total, "Counter of GitLab Pages deployments which failed")
    end
  end
end

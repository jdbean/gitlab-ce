module QA
  module Scenario
    module Test
      ##
      # Base class for running the suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      module Instance
        class All < Template
          include Bootable
          extend Taggable

          def perform(address, *rspec_options)
            Runtime::Scenario.define(:gitlab_address, address)

            ##
            # Perform before hooks, which are different for CE and EE
            #
            Runtime::Release.perform_before_hooks

            Specs::Runner.perform do |specs|
              specs.tty = true
              specs.tags = self.class.focus
              specs.options =
                if rspec_options.any?
                  rspec_options
                else
                  File.expand_path('../../specs/features', __dir__)
                end
            end
          end
        end
      end
    end
  end
end

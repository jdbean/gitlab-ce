module QA
  module Scenario
    module Test
      module Instance
        ##
        # Base class for running the suite against any GitLab instance,
        # including staging and on-premises installation.
        #
        class Smoke < Template
          extend Taggable
          include Bootable

          tags :smoke

          def perform(address, *rspec_options)
            Runtime::Scenario.define(:gitlab_address, address)

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

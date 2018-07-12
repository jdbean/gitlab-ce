module QA
  module Scenario
    module Test
      ##
      # Base class for running the suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      class Smoke < Instance
        tags :smoke
      end
    end
  end
end

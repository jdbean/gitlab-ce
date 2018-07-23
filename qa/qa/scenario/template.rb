module QA
  module Scenario
    class Template
      def self.perform(*args)
        new.tap do |scenario|
          yield scenario if block_given?
          break scenario.perform(*args)
        end
      end

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

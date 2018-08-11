require 'airborne'
require 'forwardable'

module QA
  module Factory
    class Base
      extend SingleForwardable
      include Airborne

      def_delegators :evaluator, :dependency, :dependencies
      def_delegators :evaluator, :product, :attributes

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab, new_session: false)
      end

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def fabricate_via_api!(*args)
        fabricate!(*args)
      end

      def self.fabricate_via_api!(*args, &block)
        do_fabricate!(*args, block: block, via: :api)
      end

      def self.fabricate!(*args, &block)
        do_fabricate!(*args, block: block, via: :gui)
      end

      def self.do_fabricate!(*args, block: nil, via:)
        new.tap do |factory|
          block.call(factory) if block

          dependencies.each do |signature|
            start = Time.now
            Factory::Dependency.new(factory, signature).build!
            puts "Dependency #{signature.factory} built for #{factory} built in #{Time.now - start} seconds"
          end

          case via
          when :gui
            factory.fabricate!(*args)
          when :api
            resource_url = factory.fabricate_via_api!(*args)
          else
            raise ArgumentError, "Unknown fabricate method '#{via}'. Supported methods are :gui and :api."
          end

          break Factory::Product.populate!(factory, resource_url)
        end
      end

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end

      class DSL
        attr_reader :dependencies, :attributes

        def initialize(base)
          @base = base
          @dependencies = []
          @attributes = {}
        end

        def dependency(factory, as:, &block)
          as.tap do |name|
            @base.class_eval { attr_accessor name }

            Dependency::Signature.new(name, factory, block).tap do |signature|
              @dependencies << signature
            end
          end
        end

        def product(attribute, &block)
          Product::Attribute.new(attribute, block).tap do |signature|
            @attributes.store(attribute, signature)
          end
        end
      end
    end
  end
end

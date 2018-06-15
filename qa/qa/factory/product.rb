require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      Attribute = Struct.new(:name, :block)

      def initialize(product_url)
        @location = product_url.is_a?(String) ? product_url : current_url
      end

      def visit!
        visit @location
      end

      def self.populate!(factory, product_url)
        new(product_url).tap do |product|
          factory.class.attributes.each_value do |attribute|
            product.instance_exec(factory, attribute.block) do |factory, block|
              value = block.call(factory)
              product.define_singleton_method(attribute.name) { value }
            end
          end
        end
      end
    end
  end
end

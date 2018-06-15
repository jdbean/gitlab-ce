module QA
  module Factory
    module Resource
      class Group < Factory::Base
        attr_accessor :path, :description
        attr_reader :api_object

        dependency Factory::Resource::Sandbox, as: :sandbox

        product :id do |factory|
          factory.api_object ? factory.api_object[:id] : raise("unknown id")
        end

        def initialize
          @path = Runtime::Namespace.name
          @description = "QA test run at #{Runtime::Namespace.time}"
        end

        def api_get
          response = get(Runtime::API::Request.new(api_client, "/groups/#{path}").url)
          JSON.parse(response.body, symbolize_names: true)
        end

        def api_post!
          response = post(
            Runtime::API::Request.new(api_client, '/groups').url,
            parent_id: sandbox.id,
            path: path,
            name: path)
          JSON.parse(response.body, symbolize_names: true)
        end

        def fabricate_via_api!
          @api_object = api_post!

          @api_object[:web_url]
        end

        def fabricate!
          sandbox.visit!

          Page::Group::Show.perform do |page|
            if page.has_subgroup?(@path)
              page.go_to_subgroup(@path)
            else
              page.go_to_new_subgroup

              Page::Group::New.perform do |group|
                group.set_path(@path)
                group.set_description(@description)
                group.set_visibility('Public')
                group.create
              end
            end
          end
        end
      end
    end
  end
end

module API
  module Helpers
    module HeadersHelpers
      def set_http_headers(header_data)
        header_data.each do |key, value|
          next if value.is_a?(Enumerable)

          header "X-Gitlab-#{key.to_s.split('_').collect(&:capitalize).join('-')}", value.to_s
        end
      end
    end
  end
end

module API
  class ResourceLabelEvents < Grape::API
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    EVENTABLE_TYPES = [Issue, Epic, MergeRequest].freeze

    EVENTABLE_TYPES.each do |eventable_type|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc "Get a list of #{eventable_type.to_s.downcase} resource label events" do
          success Entities::ResourceLabelEvent
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end
        get ":id/#{eventables_str}/:eventable_id/resource_label_events" do
          # FIXME: doc
          # FIXME: move&rename find_noteable to be shared both for noteables and eventables
          eventable = find_noteable(parent_type, eventables_str, params[:eventable_id])
          events = eventable.resource_label_events

          present paginate(events), with: Entities::ResourceLabelEvent
        end

        desc "Get a single #{eventable_type.to_s.downcase} resource label event" do
          success Entities::ResourceLabelEvent
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource label event'
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_label_events/:event_id" do
          eventable = find_noteable(parent_type, eventables_str, params[:eventable_id])
          event = eventable.resource_label_events.find(params[:event_id])

          present event, with: Entities::ResourceLabelEvent
        end
      end
    end
  end
end

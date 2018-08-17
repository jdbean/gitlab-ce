# frozen_string_literal: true

module ResourceEvents
  class MergeIntoNotesService
    FETCH_OVERLAP = 5.seconds

    attr_reader :resource, :params

    def initialize(resource, params = {})
      @resource = resource
      @params = params
    end

    def execute(notes)
      (notes + label_notes).sort_by { |n| n.created_at }
    end

    private

    def label_notes
      label_events_by_discussion_id.map do |discussion_id, events|
        note_from_label_events(discussion_id, events)
      end
    end

    def note_from_label_events(discussion_id, events)
      text = change_label_text(events)
      issuable = events.first.issuable
      attrs = {
        system: true,
        author: events.first.user,
        created_at: events.first.created_at,
        discussion_id: discussion_id,
        note: text,
        noteable: issuable,
        system_note_metadata: SystemNoteMetadata.new(action: 'label')
      }

      if issuable.respond_to?(:project_id)
        attrs[:project_id] = issuable.project_id
      end

      Note.new(attrs)
    end

    def label_events_by_discussion_id
      return [] unless resource.respond_to?(:resource_label_events)

      events = resource.resource_label_events.includes(:label, :user)
      # currently it's not possible to display notes without user
      # in the UI, for now we just ignore these events (other notes
      # are deleted with user so there is no change in behavior from
      # user point of view)
      events = events.where.not(user_id: nil)
      events = since_fetch_at(events)

      events.group_by { |event| event.discussion_id }
    end

    def change_label_text(events)
      added_labels = events.select { |e| e.action == 'add' }.map(&:label)
      removed_labels = events.select { |e| e.action == 'remove' }.map(&:label)

      added = labels_str('added', added_labels)
      removed = labels_str('removed', removed_labels)

      [added, removed].compact.join(' and ')
    end

    # returns string containing added/removed labels including
    # count of deleted labels:
    #
    # added ~1 ~2 + deleted label
    # added 3 deleted labels
    # added ~1 ~2 labels
    def labels_str(prefix, labels)
      names = labels.map { |label| label.to_reference(format: :id) if label.present? }.compact
      deleted = labels.count - names.count

      return nil if names.empty? && deleted == 0

      names_str = names.empty? ? nil : names.join(' ')
      deleted_str = deleted == 0 ? nil : "#{deleted} deleted"
      label_list_str = [names_str, deleted_str].compact.join(' + ')
      suffix = 'label'.pluralize(deleted > 0 ? deleted : names.count)

      "#{prefix} #{label_list_str} #{suffix}"
    end

    def since_fetch_at(events)
      return events unless params[:last_fetched_at].present?

      last_fetched_at = Time.at(params.fetch(:last_fetched_at).to_i)
      events.created_after(last_fetched_at - FETCH_OVERLAP)
    end
  end
end

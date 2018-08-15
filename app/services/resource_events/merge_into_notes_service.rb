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

      events = resource.resource_label_events.includes(:label)
      events = since_fetch_at(events)

      events.group_by { |event| event.discussion_id }
    end

    # FIXME: take from system_note, refactor
    def change_label_text(events)
      added_labels = events.select { |e| e.action == 'add' && e.label }.map(&:label)
      removed_labels = events.select { |e| e.action == 'remove' && e.label }.map(&:label)
      added_unknown_labels_count = events.select { |e| e.action == 'add' && e.label.nil? }.map(&:label).count
      removed_unknown_labels_count = events.select { |e| e.action == 'remove' && e.label.nil? }.map(&:label).count
      labels_count = added_labels.count + removed_labels.count + added_unknown_labels_count + removed_unknown_labels_count

      references     = ->(label) { label.to_reference(format: :id) }
      added_labels   = added_labels.map(&references).join(' ')
      removed_labels = removed_labels.map(&references).join(' ')

      text_parts = []

      if added_labels.present?
        text_parts << "added #{added_labels}"
        text_parts << " + #{added_unknown_labels_count} deleted" if added_unknown_labels_count > 0
        text_parts << 'and' if removed_labels.present?
      end

      if removed_labels.present?
        text_parts << "removed #{removed_labels}"
        text_parts << " + #{removed_unknown_labels_count} deleted" if removed_unknown_labels_count > 0
      end

      text_parts << 'label'.pluralize(labels_count)
      text_parts.join(' ')
    end

    def since_fetch_at(events)
      return events unless params[:last_fetched_at].present?

      last_fetched_at = Time.at(params.fetch(:last_fetched_at).to_i)
      events.created_after(last_fetched_at - FETCH_OVERLAP)
    end
  end
end

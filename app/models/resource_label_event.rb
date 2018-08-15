# frozen_string_literal: true

# This model is not used yet, it will be used for:
# https://gitlab.com/gitlab-org/gitlab-ce/issues/48483
class ResourceLabelEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :label

  scope :created_after, ->(time) { where('created_at > ?', time) }

  validates :user, presence: true, on: :create
  validates :label, presence: true, on: :create
  validate :exactly_one_issuable

  after_save :expire_etag_cache
  after_destroy :expire_etag_cache

  enum action: {
    add: 1,
    remove: 2
  }

  def self.issuable_columns
    %i(issue_id merge_request_id).freeze
  end

  def issuable
    issue || merge_request
  end

  # FIXME: check again alias_method
  def updated_at
    created_at
  end

  # create same discussion id for all actions with the same user and time
  def discussion_id(resource = nil)
    Digest::SHA1.hexdigest([self.class.name, created_at, user_id].join("-"))
  end

  private

  def exactly_one_issuable
    if self.class.issuable_columns.count { |attr| self[attr] } != 1
      errors.add(:base, "Exactly one of #{self.class.issuable_columns.join(', ')} is required")
    end
  end

  def expire_etag_cache
    return unless issuable&.discussions_rendered_on_frontend?
    return unless issuable&.etag_caching_enabled?

    Gitlab::EtagCaching::Store.new.touch(etag_key)
  end

  # FIXME: override for epic
  def etag_key
    Gitlab::Routing.url_helpers.project_noteable_notes_path(
      project,
      target_type: 'issue',
      target_id: issuable.id
    )
  end
end

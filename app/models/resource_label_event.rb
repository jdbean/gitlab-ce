# frozen_string_literal: true

# This model is not used yet, it will be used for:
# https://gitlab.com/gitlab-org/gitlab-ce/issues/48483
class ResourceLabelEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :label

  scope :created_after, ->(time) { where('created_at > ?', time) }

  validate :exactly_one_issuable

  after_save :expire_etag_cache
  after_destroy :expire_etag_cache

  enum action: {
    add: 1,
    remove: 2
  }

  def self.issuable_attrs
    %i(issue merge_request).freeze
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
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    if issuable_count == 0
      # if none of issuable IDs is set, check explicitly if nested object is set,
      # nested unsaved issuable is set during project import
      return true if self.class.issuable_attrs.count { |attr| self.public_send(attr) } == 1 # rubocop:disable GitlabSecurity/PublicSend
    elsif issuable_count == 1
      return true
    end

    errors.add(:base, "Exactly one of #{self.class.issuable_attrs.join(', ')} is required")
  end

  def expire_etag_cache
    issuable.expire_note_etag_cache
  end
end

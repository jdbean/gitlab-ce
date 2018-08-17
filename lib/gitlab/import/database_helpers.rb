# frozen_string_literal: true

module Gitlab
  module Import
    module DatabaseHelpers
      # Inserts a raw row and returns the ID of the inserted row.
      #
      # attributes - The attributes/columns to set.
      # relation - An ActiveRecord::Relation to use for finding the ID of the row
      #            when using MySQL.
      def insert_and_return_id(attributes, relation)
        # We use bulk_insert here so we can bypass any queries executed by
        # callbacks or validation rules, as doing this wouldn't scale when
        # importing very large projects.
        result = Gitlab::Database
                 .bulk_insert(relation.table_name, [attributes], return_ids: true)

        # MySQL doesn't support returning the IDs of a bulk insert in a way that
        # is not a pain, so in this case we'll issue an extra query instead.
        result.first ||
          relation.where(iid: attributes[:iid]).limit(1).pluck(:id).first
      end
    end
  end
end

# frozen_string_literal: true
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddReceiveMaxInputSizeToApplicationSettings < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :application_settings, :receive_max_input_size, :integer
  end
end

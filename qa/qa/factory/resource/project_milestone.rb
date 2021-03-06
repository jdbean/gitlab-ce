module QA
  module Factory
    module Resource
      class ProjectMilestone < Factory::Base
        attr_accessor :description

        attribute :project do
          Factory::Resource::Project.fabricate!
        end

        attribute :title

        def title=(title)
          @title = "#{title}-#{SecureRandom.hex(4)}"
          @description = 'A milestone'
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.perform do |page|
            page.click_issues
            page.click_milestones
          end

          Page::Project::Milestone::Index.perform(&:click_new_milestone)

          Page::Project::Milestone::New.perform do |milestone_new|
            milestone_new.set_title(@title)
            milestone_new.set_description(@description)
            milestone_new.create_new_milestone
          end
        end
      end
    end
  end
end

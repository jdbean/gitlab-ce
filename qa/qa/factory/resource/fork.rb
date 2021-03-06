module QA
  module Factory
    module Resource
      class Fork < Factory::Base
        attribute :push do
          Factory::Repository::ProjectPush.fabricate!
        end

        attribute :user do
          Factory::Resource::User.fabricate! do |resource|
            if Runtime::Env.forker?
              resource.username = Runtime::Env.forker_username
              resource.password = Runtime::Env.forker_password
            end
          end
        end

        def visit_project_with_retry
          # The user intermittently fails to stay signed in after visiting the
          # project page. The new user is registered and then signs in and a
          # screenshot shows that signing in was successful. Then the project
          # page is visited but a screenshot shows the user is no longer signed
          # in. It's difficult to reproduce locally but GDK logs don't seem to
          # show anything unexpected. This method attempts to work around the
          # problem and capture data to help troubleshoot.

          Capybara::Screenshot.screenshot_and_save_page

          start = Time.now

          while Time.now - start < 20
            push.project.visit!

            puts "Visited project page"
            Capybara::Screenshot.screenshot_and_save_page

            return if Page::Main::Menu.act { has_personal_area?(wait: 0) }

            puts "Not signed in. Attempting to sign in again."
            Capybara::Screenshot.screenshot_and_save_page

            Runtime::Browser.visit(:gitlab, Page::Main::Login)

            Page::Main::Login.perform do |login|
              login.sign_in_using_credentials(user)
            end
          end

          raise "Failed to load project page and stay logged in"
        end

        def fabricate!
          push
          user

          visit_project_with_retry

          Page::Project::Show.perform(&:fork_project)

          Page::Project::Fork::New.perform do |fork_new|
            fork_new.choose_namespace(user.name)
          end

          Page::Layout::Banner.perform do |page|
            page.has_notice?('The project was successfully forked.')
          end
        end
      end
    end
  end
end

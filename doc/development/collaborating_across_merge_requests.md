# Collaboration across merge requests

When features are developed that require collaboration across teams,
merge requests could grow unmanageable. To avoid getting a merge
request that becomes to large to review, consider building the
frontend and backend in separate merge requests.

In the backend merge request, the minimal UI should be built to make
the feature work. This should not yet be polished enough for users to
start using the new feature, but it should illustrate how the backend
and frontend interact.

Because the feature doesn't look good enough to ship, we should hide
all visual elements behind a feature flag. We might also consider
using checking the presence of a cookie-value, this would allow the
feature to be deployed to GitLab.com and tested while the frontend is
still being worked on.

The work on the frontend of the feature could be done at the same time
in a separate merge request based off the backend merge request. When
the backend merge request gets merged into master, this second merge
request can be rebased. The second merge request, that introduces the
polished UI for the new feature could then remove the feature flag.

By separating the work across 2 (or more) merge requests, both merge
requests would remain smaller and thus easier to review.

An example of a feature that was built in this way is the status
messages on a profile page: [The backend merge
request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/20614/)
did not include an emoji picker on the user profile. So the entire
field was hidden. [The frontend merge
request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/20903)
finished the feature, adding the emoji-picker and removing the feature
flag.

# Continuous Integration and Deployment Admin settings

In this area, you will find settings for Auto DevOps, Runners and job artifacts.
You can find it in the admin area, under **Settings > Continuous Integration and Deployment**.

![Admin area settings button](../img/admin_area_settings_button.png)

## Auto DevOps

To enable (or disable) [Auto DevOps](../../../topics/autodevops/index.md)
for all projects:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**
1. Check (uncheck to disable) the box that says "Default to Auto DevOps pipeline for all projects"
1. Optionally, set up the [Auto DevOps base domain](../../../topics/autodevops/index.md#auto-devops-base-domain).
1. Hit **Save changes** for the changes to take effect.

From now on, every project, old or new, that doesn't have a `.gitlab-ci.yml`
will use the Auto DevOps pipelines.

If you want to disable it for a specific project, you can do so in
[its settings](../../../topics/autodevops/index.md#enabling-auto-devops).

## Maximum artifacts size

The maximum size of the [job artifacts][art-yml] can be set in the Admin area
of your GitLab instance. The value is in *MB* and the default is 100MB. Note
that this setting is set for each job.

1. Go to **Admin area > Settings > Continuous Integration and Deployment**
1. Change the value of maximum artifacts size (in MB)
1. Hit **Save changes** for the changes to take effect

## Default artifacts expiration

The default expiration time of the [job artifacts][art-yml] can be set in
the Admin area of your GitLab instance. The syntax of duration is described
in [`artifacts:expire_in`][duration-syntax]. The default is `30 days`. Note that
this setting is set for each job. Set it to 0 if you don't want default
expiration.

1. Go to **Admin area > Settings > Continuous Integration and Deployment**
1. Change the value of default expiration time
1. Hit **Save changes** for the changes to take effect

[art-yml]: ../../../administration/job_artifacts.md
[duration-syntax]: ../../../ci/yaml/README.md#artifacts-expire_in

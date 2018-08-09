# GitLab permissions guide

There are multiple types of permissions across GitLab and when implementing anything that deals with permissions all of them should be considered.

## Groups and Projects

### General permissions

Groups and projects can have following visibility levels:

 - public (20) -  an entity is visible to everyone
 - internal (10) - an entity is visible to logged users
 - private (0) - an entity is visible only to the approved members of the entity

The visibility level of a group can be changed  only if all subgroups and subprojects have the same or lower visibility level. (eg. a group can be set to internal only if all subgroups and projects are internal or private).

Visibility levels can be found in `Gitlab::VisibilityLevel` module.

### Feature specific permissions

Additionally following project features can have set different visibility levels:

 - Issues
 - Repository
   - Merge Request
   - Pipelines
   - Container Registery
   - Git Large File Storage
 - Wiki
 - Snippets

These features can be set to "Everyone with Access" or "Only Project Members". These settings make sense only for public or internal projects because private projects can be accessed only by project members by default.

### Members

 Users can be members of multiple groups and projects. Following access levels are available (defined in `Gitlab::Access` module):

 - Guest
 - Reporter
 - Developer
 - Maintainer
 - Owner

If a user is the member of both a project and the project parent group the higher permission is taken into account for the project.

If a user is the member of a project but not the parent group (or groups) he/she still can read the groups and their entities (like epics).

Project membership (where the group membership is already taken into account) is stored in `project_authorizations` table.

### Confidential issues

Confidential issues can be accessed only by project members who are at least reporters (they can't be accessed by guests). Additionally they can be accessed by their authors and assignees.

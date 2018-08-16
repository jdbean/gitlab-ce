# Guidelines for reusing abstractions

As GitLab has grown, different patterns emerged across the codebase. Service
classes, serializers, and presenters are just a few. These patterns made it easy
to reuse code, but at the same time make it easy to accidentally reuse the wrong
abstraction in a particular place.

## Why these guidelines are necessary

Code reuse is good, but sometimes this can lead to shoehorning the wrong
abstraction into a particular use case. This in turn can have a negative impact
on maintainability, the ability to easily debug problems, or even performance.

An example would be to use `ProjectsFinder` in `IssuesFinder` to limit issues to
those belonging to a set of projects. While initially this may seem like a good
idea, both classes provide a very high level interface with very little control.
This means that `IssuesFinder` may not be able to produce a better optimised
database query, as a large portion of the query is controlled by the internals
of `ProjectsFinder`.

To work around this problem, you would use the same code used by
`ProjectsFinder`, instead of using `ProjectsFinder` itself directly. This allows
you to compose your behaviour better, giving you more control over the behaviour
of the code.

## End goal

The guidelines in this document are meant to foster _better_ code reuse, by
clearly defining what can be reused where, and what to do when you can not reuse
something. Clearly separating abstractions makes it harder to use the wrong one,
makes it easier to debug the code, and (hopefully) result in fewer performance
problems.

## Abstractions

Now let's take a look at the various abstraction levels available, and what they
can (or can not) reuse. For this we can use the following table, which defines
the various abstractions and what they can (not) reuse:

| Abstraction            | Service classes  | Finders  | Presenters  | Serializers   | Model class methods   | Model instance method   | Active Record   | Sidekiq
|:-----------------------|:-----------------|:---------|:------------|:--------------|:----------------------|:------------------------|:----------------|:--------
| Controller             | Yes              | Yes      | Yes         | Yes           | No                    | Yes                     | No              | No
| Service class          | Yes              | Yes      | No          | No            | No                    | Yes                     | No              | Yes
| Finder                 | No               | No       | No          | No            | Yes                   | Yes                     | No              | No
| Presenter              | No               | Yes      | No          | No            | Yes                   | Yes                     | No              | No
| Serializer             | No               | Yes      | No          | No            | Yes                   | Yes                     | No              | No
| Model class method     | No               | No       | No          | No            | Yes                   | Yes                     | Yes             | No
| Model instance method  | Yes              | Yes      | No          | No            | Yes                   | Yes                     | Yes             | Yes
| Active Record          | No               | No       | No          | No            | No                    | Yes                     | No              | No
| Sidekiq                | Yes              | Yes      | No          | No            | No                    | Yes                     | No              | Yes

### Controllers

Controllers should not do much work on their own, instead they simply pass input
to other classes and present the results.

### Service classes

Everything that resides in `app/services`. Service classes can reuse other
service classes, as long as the result of a service class is not used to
construct a query. For example, this would not be allowed:

```ruby
SomeFinder
  .new(user: current_user, projects: SomeProjectsServiceClass.new.execute)
```

### Finders

Everything in `app/finders`, typically used for retrieving data from a database.

Finders can not reuse other finders in an attempt to better control the SQL
queries they produce.

### Presenters

Everything in `app/presenters`, used for exposing complex data to a Rails view,
without having to create many instance variables.

### Serializers

Everything in `app/serializers`, used for presenting the response to a request,
typically in JSON.

### Model class methods

These are class methods defined by _GitLab itself_, including the following
methods provided by Active Record:

* `find`
* `find_by_id`

Any other methods such as `find_by(some_column: X)` are not included, and
instead fall under the "Active Record" abstraction.

### Model instance methods

Instance methods defined on Active Record models by _GItLab itself_. Methods
provided by Active Record are not included, instead they fall under the "Active
Record" abstraction.

## Active Record

The API provided by Active Record itself, such as the `where` method, `save`,
`delete_all`, etc.

### Sidekiq

The scheduling of Sidekiq jobs using `SomeWorker.perform_async`, `perform_in`,
etc. Directly invoking a worker using `SomeWorker.new.perform` should be avoided
at all times in application code, though this is fine to use in tests.

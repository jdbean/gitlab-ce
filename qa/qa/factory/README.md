# Factory objects in GitLab QA

In GitLab QA we are using factories to create resources.

Factories implementation are primarily done using Browser UI steps, but can also
be done via the API.

## Why do we need that?

We need factory objects because we need to reduce duplication when creating
resources for our QA tests.

## How to properly implement a factory object?

All factories should inherit from [`Factory::Base`](./base.rb).

There is only one mandatory method to implement to define a factory. This is the
`#fabricate!` method, which is used to build a resource via the browser UI.
Note that you should only use [Page objects](../page/README.md) to interact with
a Web page in this method.

Here is an imaginary example:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name

        def fabricate!
          Page::Dashboard::Index.perform do |dashboard_index|
            dashboard_index.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end
      end
    end
  end
end
```

### Define API implementation

A factory may also implement the three following methods to be able to create a
resource via the public GitLab API:

- `#api_get_path`: The `GET` path to fetch an existing resource.
- `#api_post_path`: The `POST` path to create a new resource.
- `#api_post_body`: The `POST` body (as a Ruby hash) to create a new resource.

Let's take the `Shirt` factory example, and add these three API methods:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attr_accessor :name

        def fabricate!
          # ... same as before
        end

        def api_get_path
          "/shirt/#{name}"
        end

        def api_post_path
          "/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

The [`Project` factory](./resource/project.rb) is a good real example of Browser
UI and API implementations.

### Define attributes

After the resource is fabricated, we would like to access the attributes on
the resource. We define the attributes with `attribute` method. Suppose
we want to access the name on the resource, we could change `attr_accessor`
to `attribute`:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attribute :name

        # ... same as before
      end
    end
  end
end
```

The difference between `attr_accessor` and `attribute` is that by using
`attribute` it can also be accessed from the product:

```ruby
shirt =
  QA::Factory::Resource::Shirt.fabricate! do |resource|
    resource.name = "GitLab QA"
  end

shirt.name # => "GitLab QA"
```

In the above example, if we use `attr_accessor :name` then `shirt.name` won't
be available. On the other hand, using `attribute :name` will allow you to use
`shirt.name`, so most of the time you'll want to use `attribute` instead of
`attr_accessor` unless we clearly don't need it for the product.

#### Resource attributes

A resource may need another resource to exist first. For instance, a project
needs a group to be created in.

To define a resource attribute, you can use the `attribute` method with a
block using the other factory to fabricate the resource.

That will allow access to the other resource from your resource object's
methods. You would usually use it in `#fabricate!`, `#api_get_path`,
`#api_post_path`, `#api_post_body`.

Let's take the `Shirt` factory, and add a `project` attribute to it:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attribute :name

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-to-create-a-shirt'
          end
        end

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end
        end

        def api_get_path
          "/project/#{project.path}/shirt/#{name}"
        end

        def api_post_path
          "/project/#{project.path}/shirts"
        end

        def api_post_body
          {
            name: name
          }
        end
      end
    end
  end
end
```

**Note that all the attributes are lazily constructed. This means if you want
a specific attribute to be fabricated first, you'll need to call the
attribute method first even if you're not using it.**

#### Product data attributes

Once created, you may want to populate a resource with attributes that can be
found in the Web page, or in the API response.
For instance, once you create a project, you may want to store its repository
SSH URL as an attribute.

Again we could use the `attribute` method with a block, using a page object
to retrieve the data on the page.

Let's take the `Shirt` factory, and define a `:brand` attribute:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attribute :name

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-to-create-a-shirt'
          end
        end

        # Attribute populated from the Browser UI (using the block)
        attribute :brand do
          Page::Shirt::Show.perform do |shirt_show|
            shirt_show.fetch_brand_from_page
          end
        end

        # ... same as before
      end
    end
  end
end
```

**Note again that all the attributes are lazily constructed. This means if
you call `shirt.brand` after moving to the other page, it'll not properly
retrieve the data because we're no longer on the expected page.**

Consider this:

```ruby
shirt =
  QA::Factory::Resource::Shirt.fabricate! do |resource|
    resource.name = "GitLab QA"
  end

shirt.project.visit!

shirt.brand # => FAIL!
```

The above example will fail because now we're on the project page, trying to
construct the brand data from the shirt page, however we moved to the project
page already. There are two ways to solve this, one is that we could try to
retrieve the brand before visiting the project again:

```ruby
shirt =
  QA::Factory::Resource::Shirt.fabricate! do |resource|
    resource.name = "GitLab QA"
  end

shirt.brand # => OK!

shirt.project.visit!

shirt.brand # => OK!
```

The attribute will be stored in the instance therefore all the following calls
will be fine, using the data previously constructed. If we think that this
might be too brittle, we could eagerly construct the data right before
ending fabrication:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        # ... same as before

        def fabricate!
          project.visit!

          Page::Project::Show.perform do |project_show|
            project_show.go_to_new_shirt
          end

          Page::Shirt::New.perform do |shirt_new|
            shirt_new.set_name(name)
            shirt_new.create_shirt!
          end

          brand # Eagerly construct the data
        end
      end
    end
  end
end
```

This will make sure we construct the data right after we created the shirt.
The drawback for this will become we're forced to construct the data even
if we don't really need to use it.

Alternatively, we could just make sure we're on the right page before
constructing the brand data:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        attribute :name

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-to-create-a-shirt'
          end
        end

        # Attribute populated from the Browser UI (using the block)
        attribute :brand do
          back_url = current_url
          visit!

          Page::Shirt::Show.perform do |shirt_show|
            shirt_show.fetch_brand_from_page
          end

          visit(back_url)
        end

        # ... same as before
      end
    end
  end
end
```

This will make sure it's on the shirt page before constructing brand, and
move back to the previous page to avoid breaking the state.

#### Define an attribute based on an API response

Sometimes, you want to define a resource attribute based on the API response
from its `GET` or `POST` request. For instance, if the creation of a shirt via
the API returns

```ruby
{
  brand: 'a-brand-new-brand',
  style: 't-shirt',
  materials: [[:cotton, 80], [:polyamide, 20]]
}
```

you may want to store `style` as-is in the resource, and fetch the first value
of the first `materials` item in a `main_fabric` attribute.

Let's take the `Shirt` factory, and define a `:style` and a `:main_fabric`
attributes:

```ruby
module QA
  module Factory
    module Resource
      class Shirt < Factory::Base
        # ... same as before

        # Attribute from the Shirt factory if present,
        # or fetched from the API response if present,
        # or a QA::Factory::Base::NoValueError is raised otherwise
        attribute :style

        # If the attribute from the Shirt factory is not present,
        # and if the API does not contain this field, this block will be
        # used to construct the value based on the API response.
        attribute :main_fabric do
          api_response.&dig(:materials, 0, 0)
        end

        # ... same as before
      end
    end
  end
end
```

**Notes on attributes precedence:**

- attributes from the factory have the highest precedence
- attributes from the API response take precedence over attributes from the
  block (usually from Browser UI)
- attributes without a value will raise a `QA::Factory::Base::NoValueError` error

## Creating resources in your tests

To create a resource in your tests, you can call the `.fabricate!` method on the
factory class.
Note that if the factory supports API fabrication, this will use this
fabrication by default.

Here is an example that will use the API fabrication method under the hood since
it's supported by the `Shirt` factory:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate! do |shirt|
  shirt.name = 'my-shirt'
end

expect(page).to have_text(my_shirt.name) # => "my-shirt" from the factory's attribute
expect(page).to have_text(my_shirt.brand) # => "a-brand-new-brand" from the API response
expect(page).to have_text(my_shirt.style) # => "t-shirt" from the API response
expect(page).to have_text(my_shirt.main_fabric) # => "cotton" from the API response via the block
```

If you explicitly want to use the Browser UI fabrication method, you can call
the `.fabricate_via_browser_ui!` method instead:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate_via_browser_ui! do |shirt|
  shirt.name = 'my-shirt'
end

expect(page).to have_text(my_shirt.name) # => "my-shirt" from the factory's attribute
expect(page).to have_text(my_shirt.brand) # => the brand name fetched from the `Page::Shirt::Show` page via the block
expect(page).to have_text(my_shirt.style) # => QA::Factory::Base::NoValueError will be raised because no API response nor a block is provided
expect(page).to have_text(my_shirt.main_fabric) # => QA::Factory::Base::NoValueError will be raised because no API response and the block didn't provide a value (because it's also based on the API response)
```

You can also explicitly use the API fabrication method, by calling the
`.fabricate_via_api!` method:

```ruby
my_shirt = Factory::Resource::Shirt.fabricate_via_api! do |shirt|
  shirt.name = 'my-shirt'
end
```

In this case, the result will be similar to calling `Factory::Resource::Shirt.fabricate!`.

## Where to ask for help?

If you need more information, ask for help on `#quality` channel on Slack
(internal, GitLab Team only).

If you are not a Team Member, and you still need help to contribute, please
open an issue in GitLab CE issue tracker with the `~QA` label.

# Elasticsearch::Model::TransactionalCallbacks

[![Gem Version](https://badge.fury.io/rb/elasticsearch-model-transactional_callbacks.svg)](https://badge.fury.io/rb/elasticsearch-model-transactional_callbacks)
[![CircleCI](https://circleci.com/gh/ignatiusreza/elasticsearch-model-transactional_callbacks.svg?style=svg)](https://circleci.com/gh/ignatiusreza/elasticsearch-model-transactional_callbacks)
[![Maintainability](https://api.codeclimate.com/v1/badges/465f50566c9c27590879/maintainability)](https://codeclimate.com/github/ignatiusreza/elasticsearch-model-transactional_callbacks/maintainability)

The [`elasticsearch-model`](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model)
works great in simplifying the integration of Ruby classes ("models") with the
[Elasticsearch](http://www.elasticsearch.org/) search and analytics engine.
But, it come short with support for updating the indexed documents asynchronously.

Built-in support for updating the indexed documents comes in the form of `Elasticsearch::Model::Callbacks`
which will updates each related documents individually inside the same thread where the changes were made.
Depending on the size of your application, and the size of the changes itself, triggering N number of
indexing request to Elasticsearch could amount to nothing, or it could slow down the request-response
cycle considerably and render it unusable.

This gem aim to solve this by providing a way to update the index asynchronously via `ActiveJob`.

## Usage

The minimum is to include `Elasticsearch::Model::TransactionalCallbacks` into any model
which could benefit from asynchronous indexing, e.g.

```ruby
class User < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::TransactionalCallbacks

  index_name 'users'
  document_type 'user'

  mappings do
    # indexes for users
  end
end
```

But, this will end up trading n+1 on updating index with n+1 on database queries in case your `#as_indexed_json`
pulls data from associated models, e.g.

```ruby
class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::TransactionalCallbacks

  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  index_name 'posts'
  document_type 'post'

  mappings dynamic: false do
    indexes :subject, type: 'text', analyzer: 'english'
    indexes :tags, type: 'keyword'
  end

  def as_indexed_json(_options = {})
    {
      subject: subject,
      tags: tags.map(&:key) # FIXME: this triggers n+1 queries
    }
  end
end
```

to get around this, you can define a `scope` called `preload_for_index` like so:

```ruby
class Post < ApplicationRecord
  # ...snip...
  scope :preload_for_import, -> { preload(:tags) }
  # ...snip...
end
```

and it will be automatically called by the library.

## Compatibility
This library is compatible and tested with Elasticsearch 5. Some works might be needed to make it works with Elasticsearch 6.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'elasticsearch-model-transactional_callbacks'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install elasticsearch-model-transactional_callbacks
```

## Contributing
Any and all kind of help are welcomed! Especially interested in:

- sample use cases which are not yet supported,
- compatibility with elasticsearch 6.0

feel free to file an issue/PR with sample mapping!

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

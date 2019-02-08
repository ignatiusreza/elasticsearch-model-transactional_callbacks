# frozen_string_literal: true

class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::TransactionalCallbacks

  belongs_to :user

  index_name User.index_name
  document_type 'post'

  mappings dynamic: false, _parent: { type: 'user' } do
    indexes :subject, type: 'text', analyzer: 'english'
  end
end

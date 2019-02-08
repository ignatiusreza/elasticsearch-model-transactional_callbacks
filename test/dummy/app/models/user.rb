# frozen_string_literal: true

class User < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::TransactionalCallbacks

  has_many :posts

  index_name 'users'
  document_type 'user'

  mappings do
    indexes :name, type: 'text', analyzer: 'english'
  end
end

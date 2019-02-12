# frozen_string_literal: true

class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::TransactionalCallbacks

  belongs_to :user
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings

  index_name User.index_name
  document_type 'post'

  mappings dynamic: false, _parent: { type: 'user' } do
    indexes :subject, type: 'text', analyzer: 'english'
    indexes :tags, type: 'keyword'
  end

  scope :preload_for_import, -> { preload(:tags) }

  def as_indexed_json(_options = {})
    {
      subject: subject,
      tags: tags.map(&:key)
    }
  end
end

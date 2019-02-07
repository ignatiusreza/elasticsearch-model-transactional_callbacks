# frozen_string_literal: true

require 'test_helper'

class Elasticsearch::Model::TransactionalCallbacks::Test < ActiveSupport::TestCase
  setup do
    create_elasticsearch_index!
  end

  private

    def create_elasticsearch_index!
      delete_elasticsearch_index!

      mappings = User.mappings.to_hash.merge Post.mappings.to_hash

      User.__elasticsearch__.client.indices.create(
        index: User.index_name,
        body: {
          mappings: mappings.to_hash
        }
      )
    end

    def delete_elasticsearch_index!
      User.__elasticsearch__.client.indices.delete index: User.index_name, ignore: 404
    end

    def fetch(resource, parent = nil)
      klass = resource.class

      Elasticsearch::Model.client.get({
        index: klass.index_name,
        type: klass.document_type,
        id: resource.id,
        parent: parent&.id,
        refresh: true
      }.compact)
    end
end

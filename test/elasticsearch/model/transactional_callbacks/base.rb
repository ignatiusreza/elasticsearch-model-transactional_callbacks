# frozen_string_literal: true

class Elasticsearch::Model::TransactionalCallbacks::BaseTest < ActiveSupport::TestCase
  setup do
    create_elasticsearch_index!
    import_fixtures!
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

    def import_fixtures!
      transform = lambda { |post|
        { index: { _id: post.id, _parent: post.user_id, data: post.__elasticsearch__.as_indexed_json } }
      }

      User.import
      Post.import transform: transform
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

    def assert_indexed(*arguments)
      assert_nothing_raised do
        fetch(*arguments)
      end
    end

    def assert_not_indexed(*arguments)
      assert_raise(Elasticsearch::Transport::Transport::Errors::NotFound) do
        fetch(*arguments)
      end
    end
end

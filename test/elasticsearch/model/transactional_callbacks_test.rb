# frozen_string_literal: true

require 'test_helper'

class Elasticsearch::Model::TransactionalCallbacks::Test < ActiveSupport::TestCase
  def setup
    super

    create_elasticsearch_index!
  end

  test 'truth' do
    assert_kind_of Module, Elasticsearch::Model::TransactionalCallbacks
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
end

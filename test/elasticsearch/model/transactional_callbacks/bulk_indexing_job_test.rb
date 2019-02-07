# frozen_string_literal: true

require 'test_helper'
require_relative '../transactional_callbacks_test'

module Elasticsearch::Model::TransactionalCallbacks
  class BulkIndexingJob::Test < Test
    test 'indexing new documents' do
      described_class.perform_now(
        user: {
          index: [
            { _id: users(:neil).id },
            { _id: users(:dewi).id }
          ]
        }
      )

      assert fetch users(:neil)
      assert fetch users(:dewi)
    end

    test 'updating indexed documents' do
      user = users :neil
      old_name = user.name
      new_name = 'Neil Richard Gaiman'

      described_class.perform_now user: { index: [{ _id: user.id }] }

      user.update name: new_name

      described_class.perform_now user: { update: [{ _id: user.id }] }

      assert_equal new_name, fetch(user).dig('_source', 'name')
      refute_equal old_name, new_name
    end

    test 'deleting indexed documents' do
      user = users :neil

      described_class.perform_now user: { index: [{ _id: user.id }] }

      assert fetch user

      described_class.perform_now user: { delete: [{ _id: user.id }] }

      assert_raise(Elasticsearch::Transport::Transport::Errors::NotFound) { fetch user }
    end

    test 'indexing new child documents' do
      post = posts(:neverwhere)

      described_class.perform_now(
        user: { index: [{ _id: users(:neil).id }] },
        post: { index: [{ _id: post.id, _parent: post.user_id }] }
      )

      assert fetch post, post.user
    end

    test 'updating indexed child documents' do
      post = posts(:neverwhere)
      old_subject = post.subject
      new_subject = 'The Seven Sisters'

      described_class.perform_now(
        user: { index: [{ _id: post.user_id }] },
        post: { index: [{ _id: post.id, _parent: post.user_id }] }
      )

      assert fetch post, post.user

      post.update subject: new_subject

      described_class.perform_now post: { update: [{ _id: post.id, _parent: post.user_id }] }

      assert_equal new_subject, fetch(post, post.user).dig('_source', 'subject')
      refute_equal old_subject, new_subject
    end

    test 'deleting indexed child documents' do
      post = posts(:neverwhere)

      described_class.perform_now(
        user: { index: [{ _id: users(:neil).id }] },
        post: { index: [{ _id: post.id, _parent: post.user_id }] }
      )

      assert fetch post, post.user

      described_class.perform_now post: { delete: [{ _id: post.id, _parent: post.user_id }] }

      assert_raise(Elasticsearch::Transport::Transport::Errors::NotFound) { fetch post, post.user }
    end

    test 'indexing missing documents' do
      assert described_class.perform_now user: { index: [{ _id: 404 }] }
    end

    test 'logging errors' do
      response = { 'errors' => 1, 'items' => ['fake items'] }
      logger = Minitest::Mock.new
      logger.expect :error, nil, ["[ELASTICSEARCH] Bulk request failed: #{response['items']}"]

      Rails.stub :logger, logger do
        User.__elasticsearch__.client.stub :bulk, response do
          described_class.perform_now user: { index: [{ _id: users(:neil).id }] }
        end
      end

      assert_mock logger
    end

    private

      def described_class
        Elasticsearch::Model::TransactionalCallbacks::BulkIndexingJob
      end
  end
end

# frozen_string_literal: true

require 'test_helper'

module Elasticsearch::Model::TransactionalCallbacks
  class BulkIndexingJob::Test < BaseTest
    include ActiveJob::TestHelper

    test 'indexing new documents' do
      users = Array.new(2) { |n| User.create! name: "new user#{n}" }

      assert_not_indexed users[0]
      assert_not_indexed users[1]

      described_class.perform_now user: { index: users.map { |user| { _id: user.id } } }

      assert_indexed users[0]
      assert_indexed users[1]
    end

    test 'updating indexed documents' do
      user = users :neil
      old_name = user.name
      new_name = 'Neil Richard Gaiman'

      assert_equal old_name, fetch(user).dig('_source', 'name')
      refute_equal old_name, new_name

      user.update name: new_name

      described_class.perform_now user: { update: [{ _id: user.id }] }

      assert_equal new_name, fetch(user).dig('_source', 'name')
    end

    test 'deleting indexed documents' do
      user = users :neil

      assert_indexed user

      described_class.perform_now user: { delete: [{ _id: user.id }] }

      assert_not_indexed user
    end

    test 'indexing new child documents' do
      post = Post.create! subject: 'new post', user: users(:neil)

      assert_not_indexed post, post.user

      described_class.perform_now(
        post: { index: [{ _id: post.id, _parent: post.user_id }] }
      )

      assert_indexed post, post.user
    end

    test 'updating indexed child documents' do
      post = posts(:neverwhere)
      old_subject = post.subject
      new_subject = 'The Seven Sisters'

      assert_equal old_subject, fetch(post, post.user).dig('_source', 'subject')
      refute_equal old_subject, new_subject

      post.update subject: new_subject

      described_class.perform_now post: { update: [{ _id: post.id, _parent: post.user_id }] }

      assert_equal new_subject, fetch(post, post.user).dig('_source', 'subject')
    end

    test 'deleting indexed child documents' do
      post = posts(:neverwhere)

      assert_indexed post, post.user

      described_class.perform_now post: { delete: [{ _id: post.id, _parent: post.user_id }] }

      assert_not_indexed post, post.user
    end

    test 'indexing missing documents' do
      assert_nothing_raised do
        described_class.perform_now user: { index: [{ _id: 404 }] }
      end
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

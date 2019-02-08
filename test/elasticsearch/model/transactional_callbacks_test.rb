# frozen_string_literal: true

require 'test_helper'

module Elasticsearch::Model::TransactionalCallbacks
  class Test < BaseTest
    include ActiveJob::TestHelper

    test 'creating 1 new document without explicit transaction' do
      user_id = next_id_for :users

      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: [{ _id: user_id }], update: [], delete: [] }
        }] do
          User.create! name: 'new user'
        end
      end

      assert_empty_index_queue
    end

    test 'creating multiple documents without explicit transaction' do
      assert_enqueued_jobs 5 do
        create_users! 5
      end

      assert_empty_index_queue
    end

    test 'creating multiple documents with explicit transaction' do
      user_id = next_id_for :users

      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: Array.new(5) { |n| { _id: user_id + n } }, update: [], delete: [] }
        }] do
          User.transaction do
            create_users! 5
          end
        end
      end

      assert_empty_index_queue
    end

    test 'nested transactions' do
      user_id = next_id_for :users

      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: Array.new(5) { |n| { _id: user_id + n } }, update: [], delete: [] }
        }] do
          ActiveRecord::Base.transaction do
            User.transaction do
              create_users! 5

              assert_no_enqueued_jobs
            end

            assert_no_enqueued_jobs
          end
        end
      end

      assert_empty_index_queue
    end

    test 'handling create, update, and delete' do
      user_id = next_id_for :users

      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: {
            index: [{ _id: user_id }],
            update: [{ _id: users(:neil).id }],
            delete: [{ _id: users(:dewi).id }]
          }
        }] do
          User.transaction do
            User.create! name: 'new user'
            users(:neil).update! name: 'Neil Richard Gaiman'
            users(:dewi).destroy
          end
        end
      end
    end

    test 'batching multiple resources' do
      user_id = next_id_for :users
      post_id = next_id_for :posts

      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: [{ _id: user_id }], update: [], delete: [] },
          post: { index: [{ _id: post_id, _parent: users(:dewi).id }], update: [], delete: [] }
        }] do
          ActiveRecord::Base.transaction do
            User.create! name: 'new user'
            Post.create! subject: 'new subject', user: users(:dewi)
          end
        end
      end
    end

    test 'error handling' do
      # rubocop:disable Lint/HandleExceptions
      begin
        ActiveRecord::Base.transaction do
          User.create! name: 'new user'
          raise
        end
      rescue RuntimeError
      end
      # rubocop:enable Lint/HandleExceptions

      assert_no_enqueued_jobs
      assert_empty_index_queue
    end

    private

      def create_users!(times)
        Array.new(times) { |n| User.create! name: "new user#{n}" }
      end

      def assert_empty_index_queue
        Elasticsearch::Model::TransactionalCallbacks::Manager.queue
      end
  end
end

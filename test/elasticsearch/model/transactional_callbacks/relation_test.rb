# frozen_string_literal: true

require 'test_helper'

module Elasticsearch::Model::TransactionalCallbacks
  class Test < BaseTest
    include ActiveJob::TestHelper

    test '#update_all' do
      assert_enqueued_jobs 2 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: [], update: User.all.map { |user| { _id: user.id } }, delete: [] }
        }] do
          User.update_all('name = UPPER(name)')
        end

        assert_enqueued_with job: indexing_job_class, args: [{
          post: { index: [], update: Post.all.map { |post| { _id: post.id, _parent: post.user_id } }, delete: [] }
        }] do
          Post.update_all('subject = UPPER(subject)')
        end
      end
    end

    test '#delete_all' do
      assert_enqueued_jobs 2 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: [], update: [], delete: User.all.map { |user| { _id: user.id } } }
        }] do
          User.delete_all
        end

        assert_enqueued_with job: indexing_job_class, args: [{
          post: { index: [], update: [], delete: Post.all.map { |post| { _id: post.id, _parent: post.user_id } } }
        }] do
          Post.delete_all
        end
      end
    end

    test 'multiple calls in a transaction' do
      assert_enqueued_jobs 1 do
        assert_enqueued_with job: indexing_job_class, args: [{
          user: { index: [], update: User.all.map { |user| { _id: user.id } }, delete: [] },
          post: { index: [], update: [], delete: Post.all.map { |post| { _id: post.id, _parent: post.user_id } } }
        }] do
          ActiveRecord::Base.transaction do
            User.update_all('name = UPPER(name)')
            Post.delete_all
          end
        end
      end
    end
  end
end

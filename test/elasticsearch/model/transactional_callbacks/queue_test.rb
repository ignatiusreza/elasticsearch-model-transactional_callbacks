# frozen_string_literal: true

require 'test_helper'
require_relative '../transactional_callbacks_test'

module Elasticsearch::Model::TransactionalCallbacks
  class Queue::Test < Test
    attr_reader :queue

    setup do
      @queue = described_class.new
    end

    test 'initially empty' do
      assert_empty queue
    end

    test 'queueing new type of documents' do
      user = users(:neil)

      queue.push :index, user

      assert_equal({ user: { index: [{ _id: user.id }], update: [], delete: [] } }, queue.to_h)
    end

    test 'queueing the same type of documents multiple times' do
      queue.push :update, users(:neil)
      queue.push :delete, users(:dewi)

      assert_equal({
        user: { index: [], update: [{ _id: users(:neil).id }], delete: [{ _id: users(:dewi).id }] }
      }, queue.to_h)
    end

    test 'queueing multiple type of documents on which some have parent-child mapping' do
      user = users(:neil)
      post = posts(:neverwhere)

      queue.push :index, user
      queue.push :index, post

      assert_equal({
        user: { index: [{ _id: user.id }], update: [], delete: [] },
        post: { index: [{ _id: post.id, _parent: post.user_id }], update: [], delete: [] }
      }, queue.to_h)
    end

    private

      def described_class
        Elasticsearch::Model::TransactionalCallbacks::Queue
      end
  end
end

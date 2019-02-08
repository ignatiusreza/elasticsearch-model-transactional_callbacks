# frozen_string_literal: true

require 'elasticsearch/model'
require_relative './transactional_callbacks/railtie'
require_relative './transactional_callbacks/manager'

module Elasticsearch
  module Model
    # Extend ElasticSearch::Model with transactional callbacks for asynchronous indexing
    module TransactionalCallbacks
      extend ActiveSupport::Concern

      included do
        after_commit :batch_index_document, on: :create
        after_commit :batch_update_document, on: :update
        after_commit :batch_delete_document, on: :destroy
      end

      def batch_index_document
        Manager.queue.push(:index, self)
      end

      def batch_update_document
        Manager.queue.push(:update, self)
      end

      def batch_delete_document
        Manager.queue.push(:delete, self)
      end
    end
  end
end

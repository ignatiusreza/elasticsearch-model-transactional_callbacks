# frozen_string_literal: true

require 'elasticsearch/model'
require_relative './transactional_callbacks/railtie'
require_relative './transactional_callbacks/bulk_indexing_job'
require_relative './transactional_callbacks/queue'

module Elasticsearch
  module Model
    # Extend ElasticSearch::Model with transactional callbacks for asynchronous indexing
    module TransactionalCallbacks
      # Your code goes here...
    end
  end
end

# frozen_string_literal: true

require_relative './transaction'

module Elasticsearch
  module Model
    module TransactionalCallbacks
      class Railtie < ::Rails::Railtie # :nodoc:
        initializer 'elasticsearch.model.transactional_callbacks.initialize' do
          ActiveSupport.on_load(:active_record) do
            extend Elasticsearch::Model::TransactionalCallbacks::Transaction
          end
        end
      end
    end
  end
end

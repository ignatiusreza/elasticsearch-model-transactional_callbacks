# frozen_string_literal: true

require_relative './manager'

module Elasticsearch
  module Model
    module TransactionalCallbacks
      ##
      # Override ActiveRecord::Base.transaction to allow Manager to listen for
      # any indexing request from active record after_commit callback
      #
      # This module are automatically included into ActiveRecord::Base inside of railtie
      #
      module Transaction
        def transaction(*args, &block)
          Manager.capture do
            super(*args, &block)
          end
        end
      end
    end
  end
end

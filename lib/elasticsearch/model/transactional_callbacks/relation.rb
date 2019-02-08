# frozen_string_literal: true

require_relative './manager'

module Elasticsearch
  module Model
    module TransactionalCallbacks
      ##
      # Override .update_all and .delete_all of ActiveRecord::Relation to batch update/delete
      # the index if the resources in question have a coresponding elasticsearch index
      #
      # This module are automatically included into ActiveRecord::Relation inside of railtie
      #
      module Relation
        def update_all(*arguments)
          Manager.capture do
            Manager.queue.push_all(:update, self)

            super(*arguments)
          end
        end

        def delete_all
          Manager.capture do
            Manager.queue.push_all(:delete, self)

            super
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative './bulk_indexing_job'
require_relative './queue'

module Elasticsearch
  module Model
    module TransactionalCallbacks
      module Manager # :nodoc:
        class << self
          def capture
            counter_stack.push(:lol)

            yield.tap do
              register_job if counter_stack.length == 1
            end
          ensure
            counter_stack.pop
          end

          def queue
            Thread.current[:elasticsearch_transactional_queue] ||= Queue.new
          end

          private

            def counter_stack
              Thread.current[:elasticsearch_transactional_counter] ||= []
            end

            def register_job
              return if queue.empty?

              BulkIndexingJob.perform_later(queue.to_h)

              queue.reset!
            end
        end
      end
    end
  end
end

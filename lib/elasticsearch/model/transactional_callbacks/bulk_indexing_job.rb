# frozen_string_literal: true

module Elasticsearch
  module Model
    module TransactionalCallbacks
      ##
      # Background job which handles the request to index/update/delete documents asynchronously
      #
      #   Elasticsearch::Model::TransactionalCallbacks::BulkIndexingJob.perform_later(
      #     document_type: {
      #       index: [{ _id: document.id }],
      #       update: [{ _id: document.id }],
      #       delete: [{ _id: document.id }],
      #     }
      #   )
      #
      class BulkIndexingJob < ::ActiveJob::Base
        queue_as :default

        def perform(indexables)
          indexables.each do |document_type, action_map|
            klass = document_type.to_s.camelcase.constantize
            body = transform_batches(klass, action_map)

            response = bulk_index klass, body

            Rails.logger.error "[ELASTICSEARCH] Bulk request failed: #{response['items']}" if response&.dig('errors')
          end
        end

        private

          def transform_batches(klass, action_map)
            reverse_map = build_reverse_map(action_map)

            klass.where(id: reverse_map.keys).find_each.map { |resource|
              action, option = reverse_map[resource.id]

              send "transform_#{action}", resource, option
            } + action_map.fetch(:delete, []).map { |option|
              transform_delete(option)
            }
          end

          def build_reverse_map(action_map)
            action_map.each_with_object({}) { |map, memo|
              action, options = map

              next if action == :delete

              options.each do |option|
                memo[option[:_id]] = [action, option]
              end
            }
          end

          def transform_index(resource, option)
            { index: option.merge(data: to_indexed_json(resource)) }
          end
          # elasticsearch do support update operation in their bulk API,
          # but it will fail in case the update is done to missing documents,
          # while index work for both new and existing document
          #
          # because of this, we choose to use index for update to avoid issue with race condition
          # where a document is updated immediately after it is created,
          # on which elasticsearch might not be aware of the document yet
          alias transform_update transform_index

          def transform_delete(option)
            { delete: option }
          end

          def to_indexed_json(resource)
            return resource.as_indexed_json if resource.respond_to?(:as_indexed_json)

            resource.__elasticsearch__.as_indexed_json
          end

          def bulk_index(klass, body)
            return if body.blank?

            klass.__elasticsearch__.client.bulk(
              index: klass.index_name,
              type: klass.document_type,
              body: body
            )
          end
      end
    end
  end
end

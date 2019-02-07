# frozen_string_literal: true

module Elasticsearch
  module Model
    module TransactionalCallbacks
      ##
      #  Responsible for storing a queue of resources to be indexed/updated/deleted from elasticsearch
      #
      class Queue
        attr_reader :state

        delegate :empty?, to: :state

        def initialize
          reset!
        end

        def reset!
          @state = {}
        end

        def push(action, resource)
          type = document_type(resource)

          prepare_state_for(type)

          state[type][action] << { _id: resource.id, _parent: parent_id(resource) }.compact
          state[type][action].uniq!
        end

        def to_h
          state
        end

        private

          def prepare_state_for(type)
            state[type] ||= {
              index: [],
              update: [],
              delete: []
            }
          end

          def resource_class(resource)
            resource.respond_to?(:document_type) ? resource : resource.class
          end

          def document_type(resource)
            resource_class(resource).document_type.to_sym
          end

          def child?(resource)
            parent_type(resource).present?
          end

          def parent_type(resource)
            resource_class(resource).mapping.options.dig(:_parent, :type)
          end

          def parent_id(resource)
            return unless child?(resource)

            resource.public_send "#{parent_type resource}_id"
          end
      end
    end
  end
end

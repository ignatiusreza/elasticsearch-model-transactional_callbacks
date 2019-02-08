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
          do_push action, resource, _id: resource.id, _parent: parent_id(resource)
        end

        def push_all(action, relation)
          return unless ::Elasticsearch::Model::TransactionalCallbacks.in?(relation.included_modules)

          pluck_ids(relation) do |ids|
            do_push action, relation, ids
          end
        end

        def to_h
          state
        end

        private

          def do_push(action, resource_or_relation, options)
            type = document_type(resource_or_relation)

            prepare_state_for(type)

            state[type][action] << options.compact
            state[type][action].uniq!
          end

          def prepare_state_for(type)
            state[type] ||= {
              index: [],
              update: [],
              delete: []
            }
          end

          def resource_class(resource_or_relation)
            resource_or_relation.respond_to?(:document_type) ? resource_or_relation : resource_or_relation.class
          end

          def document_type(resource_or_relation)
            resource_class(resource_or_relation).document_type.to_sym
          end

          def child?(resource_or_relation)
            parent_type(resource_or_relation).present?
          end

          def parent_type(resource_or_relation)
            resource_class(resource_or_relation).mapping.options.dig(:_parent, :type)
          end

          def parent_id(resource)
            return unless child?(resource)

            resource.public_send "#{parent_type resource}_id"
          end

          def pluck_ids(relation)
            if child?(relation)
              relation.pluck(:id, "#{parent_type relation}_id").map do |ids|
                yield _id: ids[0], _parent: ids[1]
              end
            else
              relation.pluck(:id).map do |id|
                yield _id: id
              end
            end
          end
      end
    end
  end
end

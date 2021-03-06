module Elasticsearch
  module Persistence
    module Repository
      class DocumentNotFound < StandardError; end

      # Retrieves one or more domain objects from the repository
      #
      module Find

        # Retrieve a single object or multiple objects from Elasticsearch by ID or IDs
        #
        # @example Retrieve a single object by ID
        #
        #     repository.find(1)
        #     # => <Note ...>
        #
        # @example Retrieve multiple objects by IDs
        #
        #     repository.find(1, 2)
        #     # => [<Note ...>, <Note ...>
        #
        # @return [Object,Array]
        #
        def find(*args)
          options  = args.last.is_a?(Hash) ? args.pop : {}
          ids      = args

          if args.size == 1
            id = args.pop
            id.is_a?(Array) ? __find_many(id, options) : __find_one(id, options)
          else
            __find_many args, options
          end
        end

        # Return if object exists in the repository
        #
        # @example
        #
        #     repository.exists?(1)
        #     => true
        #
        # @return [true, false]
        #
        def exists?(id, options={})
          type     = document_type || (klass ? __get_type_from_class(klass) : '_all')
          client.exists( { index: index_name, type: type, id: id }.merge(options) )
        end

        # @api private
        #
        def __find_one(id, options={})
          type     = document_type || (klass ? __get_type_from_class(klass) : '_all')
          document = client.get( { index: index_name, type: type, id: id }.merge(options) )

          deserialize(document)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
          raise DocumentNotFound, e.message, caller
        end

        # @api private
        #
        def __find_many(ids, options={})
          type     = document_type || (klass ? __get_type_from_class(klass) : '_all')
          documents = client.mget( { index: index_name, type: type, body: { ids: ids } }.merge(options) )

          documents['docs'].map { |document| document['found'] ? deserialize(document) : nil }
        end
      end

    end
  end
end

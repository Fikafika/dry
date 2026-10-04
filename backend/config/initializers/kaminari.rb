require 'kaminari'

Kaminari::Hooks.init if defined?(Kaminari::Hooks)
OpenSearch::Model::Response::Response.__send__ :include, OpenSearch::Model::Response::Pagination::Kaminari


require 'test_helper'

class Elasticsearch::Model::TransactionalCallbacks::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Elasticsearch::Model::TransactionalCallbacks
  end
end

# frozen_string_literal: true

module LowAuthSpec
  class AdminNode < LowNode
    extend LowAuth::Guard
    include Controller

    requires :admin

    def get = 'admin page'
    def post = 'posted'
  end

  class MembersNode < LowNode
    extend LowAuth::Guard
    include Controller

    requires

    def get = 'members page'
  end
end

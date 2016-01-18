require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type
    class VPNGateway < Base

      def initialize(vgw)
        @vgw = vgw
      end

      def has_name?(name)
        @vgw.tags['Name'] == name
      end
    end
  end
end
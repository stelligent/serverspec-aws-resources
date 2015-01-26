require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type


    class Subnets < Base

      def initialize(subnets)
        @subnets = subnets
      end

      def has_cidr_blocks?(expected_cidr_blocks)
        actual_cidr_blocks = @subnets.map { |subnet| subnet.cidr_block }
        actual_cidr_blocks - expected_cidr_blocks == [] and expected_cidr_blocks - actual_cidr_blocks == []
      end

      def size
        @subnets.size
      end
    end
  end
end

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

      def evenly_split_across_az?(num_azs)
        raise 'must specify at least 1' if num_azs < 1
        subnet_grouping_by_az = @subnets.group_by(&:availability_zone_name)
        return false if number_of_sizes_in_sub_arrays(subnet_grouping_by_az) != 1
        return false if subnet_grouping_by_az.size != num_azs
        true
      end

      private

      def number_of_sizes_in_sub_arrays(arr)
        arr.map { |sub_arr| sub_arr.size }.uniq.size
      end
    end
  end
end

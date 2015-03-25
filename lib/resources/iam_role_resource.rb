require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type

    class IAMRole < Base

      def initialize(role_name)
        @role_name = role_name
        @iam = AWS::IAM::Client.new
      end

      def content
        iam.get_role(role_name: @role_name)[:role]
      end

      def has_policy?(policy_json)
        content.policy.to_json == policy_json
      end

      def has_number_of_policies?(expected_number_of_policies)
        @iam.list_role_policies(role_name: @role_name)[:policy_names].size == expected_number_of_policies
      end

      def has_assume_role_policy_document?(expected_assume_role_policy_document)
        content[:assume_role_policy_document] == expected_assume_role_policy_document
      end

      def has_policy_with_name?(expected_policy_name)
        @iam.list_role_policies(role_name: @role_name)[:policy_names].include? expected_policy_name
      end

      def to_s
        "iam role: #{@role_name}"
      end

    end

    #this is how the resource is called out in a spec
    def iam_role(role_name)
      IAMRole.new(role_name)
    end

  end
end

include Serverspec::Type
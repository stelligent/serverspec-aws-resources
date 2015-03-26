require 'aws-sdk'
require 'serverspec'
require 'uri'

module Serverspec
  module Type

    class IAMRole < Base

      def initialize(role_name)
        @role_name = role_name
        @iam = AWS::IAM::Client.new
      end

      def content
        @iam.get_role(role_name: @role_name)[:role]
      end

      def has_policy?(policy_json)
        content.policy.to_json == policy_json
      end

      def has_number_of_policies?(expected_number_of_policies)
        @iam.list_role_policies(role_name: @role_name)[:policy_names].size == expected_number_of_policies
      end

      def has_assume_role_policy_document?(expected_assume_role_policy_document)
        actual_policy_document = JSON.parse(URI.decode(content[:assume_role_policy_document]))
        puts actual_policy_document
        actual_statements = actual_policy_document['Statement'].map { |statement| {effect: statement['Effect'], principal: statement['Principal'], action: statement['Action']}}
        Set.new(actual_statements) == expected_assume_role_policy_document
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
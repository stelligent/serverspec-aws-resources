require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type

    class IAMRole < Base

      def initialize(iam_role_arn)
        @iam_role_arn = iam_role_arn
      end

      def content
        iam = AWS::IAM.new
        iam.role[@iam_role_arn]
      end

      def has_display_name?(display_name)
        content.display_name == display_name
      end

      def has_name?(name)
        content.name == name
      end

      def has_policy?(policy_json)
        content.policy.to_json == policy_json
      end

      def to_s
        "iam role: #{@iam_role_arn}"
      end

    end

    #this is how the resource is called out in a spec
    def iam_role(iam_role_arn)
      IAMRole.new(iam_role_arn)
    end

  end
end

include Serverspec::Type
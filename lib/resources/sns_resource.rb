require 'aws-sdk-v1'
require 'serverspec'
require 'set'

module Serverspec
  module Type

    class SNSTopic < Base

      def initialize(sns_topic_arn)
        @sns_topic_arn = sns_topic_arn
      end

      def content
        sns = AWS::SNS.new
        sns.topics[@sns_topic_arn]
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

      def has_subscriptions(expected_subscriptions)
        actual_subscriptions = content.subscriptions.map do |subscription|
          { :arn => subscription.arn, :endpoint => subscription.endpoint, :protocol => protocol }
        end
        Set.new(actual_subscriptions) == Set.new(expected_subscriptions)
      end

      def to_s
        "sns topic: #{@sns_topic_arn}"
      end

    end

    #this is how the resource is called out in a spec
    def sns_topic(sns_topic_arn)
      SNSTopic.new(sns_topic_arn)
    end

  end
end

include Serverspec::Type
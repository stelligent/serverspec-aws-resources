require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type

    class SQSQueue < Base

      def initialize(queue_name)
        @queue_name = queue_name
      end

      def content
        sqs = AWS::SQS.new
        sqs.queues[@queue_name]
      end

      def has_delay_seconds?(delay_seconds)
        content.delay_seconds == delay_seconds
      end

      def has_maximum_message_size?(maximum_message_size)
        content.maximum_message_size == maximum_message_size
      end

      def has_message_retention_period?(message_retention_period)
        content.message_retention_period == message_retention_period
      end

      def has_receive_message_wait_time_seconds?(receive_message_wait_time_seconds)
        content.wait_time_seconds == receive_message_wait_time_seconds
      end

      def has_visibility_timeout?(visibility_timeout)
        content.visibility_timeout == visibility_timeout
      end

      def has_redrive_policy?
        not content.policy.nil?
      end

      def has_visibility_timeout?(visibility_timeout)
        content.visibility_timeout == visibility_timeout
      end

      def has_redrive_policy_dead_letter_target_arn?(dead_letter_target_arn)
        if content.policy.nil?
          false
        else
          content.policy.to_h['deadLetterTargetArn'] == dead_letter_target_arn
        end
      end

      def has_redrive_policy_max_receive_count?(max_receive_count)
        if content.policy.nil?
          false
        else
          content.policy.to_h['maxReceiveCount'] == max_receive_count
        end
      end

      def to_s
        "sqs queue: #{@queue_name}"
      end
    end

    #this is how the resource is called out in a spec
    def sqs_queue(queue_name)
      SQSQueue.new(queue_name)
    end
  end
end

include Serverspec::Type
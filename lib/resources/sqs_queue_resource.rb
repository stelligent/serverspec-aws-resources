require 'aws-sdk-v1'
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

      #redrive policy AWS::SQS::Client.get_queue_attributes

      def policy_statements
        content.statements.map { |statement| policy_statement(statement) }
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
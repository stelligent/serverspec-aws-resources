require 'aws-sdk-v1'
require 'serverspec'

module Serverspec
  module Type

    class SWFActivityType < Base

      def initialize(domain_name, activity_type_name, activity_type_version)
        @domain_name = domain_name
        @activity_type_name = activity_type_name
        @activity_type_version = activity_type_version
      end

      def content
        domain = AWS::SimpleWorkflow.new.domains[@domain_name]
        raise "#{@domain_name} not found" if domain.nil?

        found_wf_type = domain.activity_types.enum.find do |activity_type|
          activity_type.name == @activity_type_name and activity_type.version == @activity_type_version
        end
        raise "#{@activity_type_name}/#{@activity_type_version} is not found" if found_wf_type.nil?
        found_wf_type
      end

      def registered?
        content.status == :registered
      end

      def deprecated?
        content.deprecated?
      end

      def has_description?(expected_description)
        content.description == expected_description
      end

      def has_default_task_heartbeat_timeout?(expected_default_task_heartbeat_timeout)
        content.default_task_heartbeat_timeout.to_s.downcase == expected_default_task_heartbeat_timeout.to_s.downcase
      end

      def has_default_task_list?(expected_default_task_list)
        content.default_task_list.to_s == expected_default_task_list.to_s
      end

      def has_default_task_priority?(expected_default_task_priority)
        content.default_task_priority.to_s == expected_default_task_priority.to_s
      end

      def has_default_task_schedule_to_close_timeout?(expected_default_task_schedule_to_close_timeout)
        content.default_task_schedule_to_close_timeout.to_s.downcase == expected_default_task_schedule_to_close_timeout.to_s.downcase
      end

      def has_default_task_schedule_to_start_timeout?(expected_default_task_schedule_to_start_timeout)
        content.default_task_schedule_to_start_timeout.to_s.downcase == expected_default_task_schedule_to_start_timeout.to_s.downcase
      end

      def has_default_task_start_to_close_timeout?(expected_default_task_start_to_close_timeout)
        content.default_task_start_to_close_timeout.to_s.downcase == expected_default_task_start_to_close_timeout.to_s.downcase
      end

      def to_s
        "SWF Activity type: #{@activity_type_name}, #{@activity_type_version}"
      end

    end

    def swf_activity_type(domain_name, activity_type_name, activity_type_version)
      SWFActivityType.new(domain_name, activity_type_name, activity_type_version)
    end
  end
end

include Serverspec::Type
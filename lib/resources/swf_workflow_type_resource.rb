require 'aws-sdk'
require 'serverspec'

module Serverspec
  module Type

    class SWFWorkfowType < Base

      def initialize(domain_name, workflow_type_name, workflow_type_version)
        @domain_name = domain_name
        @workflow_type_name = workflow_type_name
        @workflow_type_version = workflow_type_version
      end

      def content
        domain = AWS::SimpleWorkflow.new.domains[@domain_name]
        raise "#{@domain_name} not found" if domain.nil?

        found_wf_type = domain.workflow_types.enum.find do |workflow_type|
          workflow_type.name == @workflow_type_name and workflow_type.version == @workflow_type_version
        end
        raise "#{@workflow_type_name}/#{@workflow_type_version} is not found" if found_wf_type.nil?
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

      def has_default_task_priority?(expected_default_task_priority)
        content.default_task_priority.to_s == expected_default_task_priority.to_s
      end

      def has_default_child_policy?(expected_default_child_policy)
        content.default_child_policy.to_s.downcase == expected_default_child_policy.to_s.downcase
      end

      def has_default_execution_start_to_close_timeout?(expected_default_execution_start_to_close_timeout)
        content.default_execution_start_to_close_timeout.to_s.downcase == expected_default_execution_start_to_close_timeout.to_s.downcase
      end

      def has_default_task_list_name?(expected_default_task_list)
        content.default_task_list.to_s.downcase == expected_default_task_list.to_s.downcase
      end

      def to_s
        "SWF wf: #{@workflow_type_name},#{@workflow_type_version}"
      end
    end

    def swf_workflow_type(domain_name, workflow_type_name, workflow_type_version)
      SWFWorkfowType.new(domain_name, workflow_type_name, workflow_type_version)
    end
  end
end

include Serverspec::Type
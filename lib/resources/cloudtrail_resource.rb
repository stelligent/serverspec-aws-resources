require 'aws-sdk-v1'
require 'serverspec'

module Serverspec
  module Type
    
    class CloudTrail < Base
      
      def initialize(trail_name)
        @trail_name = trail_name
      end
      
      def content
        @trail ||= AWS::CloudTrail.new.client.describe_trails[:trail_list].find {|trail| trail[:name] == @trail_name }
      end

      def status
        @trail_status ||= AWS::CloudTrail.new.client.get_trail_status({name: @trail_name})
      end

      def valid?
        not content.nil? 
      end

      def to_s
        "CloudTrail Trail: #{@trail_name}"
      end

      def multi_region_trail?
        content[:is_multi_region_trail] == "true"
      end

      def including_global_service_events?
        content[:include_global_service_events]
      end

      def logging?
        status[:is_logging]
      end
    end
    
    def cloudtrail_trail(trail_name)
      CloudTrail.new(trail_name)
    end
  end
end

include Serverspec::Type
require 'aws-sdk'
require 'serverspec'

module Serverspec
	module Type
		
		class SWFDomain < Base
			
			def initialize(domain_name)
				@domain_name = domain_name
			end
			
			def content
				AWS::SimpleWorkflow.new.domains[@domain_name]
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

      def has_retention_period?(expected_retention_period)
        content.retention_period.to_s == expected_retention_period
      end
		end

		def swf_domain(domain_name)
      SWFDomain.new(domain_name)
		end
	end
end

include Serverspec::Type
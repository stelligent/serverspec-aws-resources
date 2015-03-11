require 'aws-sdk'
require 'serverspec'

module Serverspec
	module Type
		
		class SWF < Base
			
			def initialize(domain_name)
				@domain_name = domain_name
			end
			
			def content
				AWS::SimpleWorkflow.new.domains[@domain_name]
			end

			def valid?
				content.exists? 
			end
		end

		def swf_domain(domain_name)
			SWF.new(domain_name)
		end
	end
end

include Serverspec::Type
require 'aws-sdk-v1'
require 'serverspec'

module Serverspec
	module Type
		
		class DynamoDB < Base
			
			def initialize(table_name)
				@table_name = table_name
			end
			
			def content
				AWS::DynamoDB.new.tables[@table_name]
			end

			def valid?
				content.exists? 
      end

      def to_s
        "DynamoDB Table: #{@table_name}"
      end
		end
    
		def dynamo_db_table(table_name)
			DynamoDB.new(table_name)
		end
	end
end

include Serverspec::Type
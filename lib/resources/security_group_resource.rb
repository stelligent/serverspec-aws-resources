require 'aws-sdk'
require 'serverspec'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class SecurityGroup < Base

      include Serverspec::Type::SecurityGroups

      def initialize(sg_tag_name_value)
        @sg_tag_name_value = sg_tag_name_value
      end

      def content
        found_group_name = nil

        AWS::EC2.new.security_groups.each do |group|
          group.tags.to_h.each do |tag|
            puts "TAG: #{tag}"
            if tag[:key] == 'Name' and tag[:value] == @sg_tag_name_value
              found_group_name = group.name
            end
          end
        end

        if found_group_name == nil
          raise "no match found for #{@group_name}"
        else
          AWS::EC2.new.security_groups[found_group_name]
        end
      end
    end

    #this is how the resource is called out in a spec
    def security_group(sg_tag_name_value)
      SecurityGroup.new(sg_tag_name_value)
    end
  end
end

include Serverspec::Type

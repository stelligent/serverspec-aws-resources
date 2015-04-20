require 'aws-sdk'
require 'serverspec'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class SecurityGroup < Base

      include Serverspec::Type::SecurityGroups

      def initialize(sg_tag_name_value, sg_id=nil)
        @sg_tag_name_value = sg_tag_name_value
        @sg_id = sg_id
      end

      def content
        if @sg_id.nil?
          find_sg_by_name_tag
        else
          AWS::EC2.new.security_groups[@sg_id]
        end
      end

      def to_s
        @sg_tag_name_value
      end

      private

      def find_sg_by_name_tag
        found_group_id = nil

        AWS::EC2.new.security_groups.each do |group|
          group.tags.to_h.each do |tag_name, tag_value|
            if tag_name == 'Name' and tag_value == @sg_tag_name_value
              found_group_id = group.id
            end
          end
        end

        if found_group_id == nil
          raise "no match found for #{@sg_tag_name_value}"
        else
          AWS::EC2.new.security_groups[found_group_id]
        end
      end
    end

    #this is how the resource is called out in a spec
    def security_group(sg_tag_name_value)
      SecurityGroup.new(sg_tag_name_value)
    end

    def security_group_by_id(sg_id)
      SecurityGroup.new(nil, sg_id)
    end
  end
end

include Serverspec::Type

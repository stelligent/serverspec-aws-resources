require 'aws-sdk'
require 'serverspec'


module Serverspec
  module Type

    class EC2Instance < Base

      def initialize(ec2instance)
        @ec2instance = ec2instance
      end

      def has_source_dest_checking_disabled?
        @ec2instance.source_dest_check
      end

      def has_ingress_rules?(expected_ingress_rules)
        actual_ingress_rules = Set.new
        @ec2instance.security_groups.each do |sg|
          sg.ingress_ip_permissions.each do |perm|
            if perm.groups == []
              actual_ingress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :ip_ranges=>perm.ip_ranges}
            else
              actual_ingress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :groups=>perm.groups}
            end
          end
        end

        actual_ingress_rules.should == Set.new(expected_ingress_rules)
      end

      #this is duplicative
      def has_egress_rules?(expected_egress_rules)
        actual_egress_rules = Set.new
        @ec2instance.security_groups.each do |sg|
          sg.egress_ip_permissions.each do |perm|
            if perm.groups == []
              actual_egress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :ip_ranges=>perm.ip_ranges}
            else
              actual_egress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :groups=>perm.groups}
            end
          end
        end

        actual_egress_rules.should == Set.new(expected_egress_rules)
      end
    end
  end
end

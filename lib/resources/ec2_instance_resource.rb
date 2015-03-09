require 'aws-sdk'
require 'serverspec'


module Serverspec
  module Type

    class EC2Instance < Base

      def initialize(instance_id)
        @instance_id = instance_id
        @ec2instance = AWS::EC2.instances[instance_id]
      end

      def has_user_data?(user_data)
        @ec2instance.user_data == user_data
      end

      def is_ebs_optimized?
        @ec2instance.ebs_optimized
      end

      def is_x86_64_architecture?
        @ec2instance.architecture == :x86_64
      end

      def is_i386_architecture?
        @ec2instance.architecture == :i386
      end

      def is_para_virtualization?
        @ec2instance.virtualization_type == :paravirtual
      end

      def is_hvm_virtualization?
        @ec2instance.virtualization_type == :hvm
      end

      def has_key_name?(key_name)
        @ec2instance.key_name == key_name
      end

      def has_image_id?(image_id)
        @ec2instance.image_id == image_id
      end

      def has_instance_type?(instance_type)
        @ec2instance.instance_type == instance_type
      end

      def has_source_dest_checking_disabled?
        not @ec2instance.source_dest_check
      end

      def has_api_termination_disabled?
        @ec2instance.api_termination_disabled?
      end

      def has_elastic_ip?
        @ec2instance.has_elastic_ip?
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

    #this is how the resource is called out in a spec
    def ec2_instance(instance_id)
      EC2Instance.new(instance_id)
    end

  end
end

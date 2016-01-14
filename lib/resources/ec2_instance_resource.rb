require 'aws-sdk'
require 'serverspec'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class EC2Instance < Base
      include SecurityGroups

      def initialize(instance_id, region)
        @instance_id = instance_id
        @region = region
      end

      def content
        Aws::EC2::Instance.new(instance_id, region: @region)
      end

      #hmmm is serverspec already messing with method_missing? maybe just fwd anything to ec2instance?
      def lauch_time
        content.launch_time
      end

      def is_ebs_optimized?
        content.ebs_optimized
      end

      def is_api_termination_disabled?
        content.describe_attribute({attribute: 'disableApiTermination'}).disable_api_termination.value
      end

      def is_x86_64_architecture?
        content.architecture == :x86_64
      end

      def is_i386_architecture?
        content.architecture == :i386
      end

      def is_paravirtual_virtualization?
        content.virtualization_type == :paravirtual
      end

      def is_hvm_virtualization?
        content.virtualization_type == :hvm
      end

      def is_ebs_optimized?
        content.ebs_optimized
      end

      def is_xen_hypervisor?
        content.hypervisor == 'xen'
      end

      def is_oracle_vm_hypervisor?
        content.hypervisor == 'ovm'
      end

      def shutdown_behavior
        content.describe_attribute({attribute: 'instanceInitiatedShutdownBehavior'}).instance_initiated_shutdown_behavior.value
      end
      
      def is_stop_shutdown_behavior?
        shutdown_behavior == 'stop'
      end

      def is_termination_shutdown_behavior?
        shutdown_behavior == 'terminate'
      end

      def is_monitoring_disabled?
        content.monitoring.state == 'disabled'
      end

      def is_monitoring_enabled?
        content.monitoring.state == 'enabled'
      end

      def is_monitoring_pending?
        content.monitoring.state == 'pending'
      end

      def is_windows_platform?
        content.platform == "Windows"
      end

      # def method_missing(sym, *args, &block)
      #   @ec2_instance.send sym, *args, &block
      # end

      # TODO: FIND OUT HOW TO RETRIEVE OWNER_ID in Aws-Sdk-V2
      # def has_owner_id(owner_id)
      #   content.owner_id == owner_id
      # end

      def has_iam_instance_profile_arn?(iam_instance_profile_arn)
        content.iam_instance_profile.arn == iam_instance_profile_arn
      end

      def has_iam_instance_profile_id?(iam_instance_profile_id)
        content.iam_instance_profile.id == iam_instance_profile_id
      end

      def has_private_dns_name?(private_dns_name)
        content.private_dns_name == private_dns_name
      end

      def has_public_dns_name?(public_dns_name)
        content.pubic_dns_name == public_dns_name
      end

      def has_ami_launch_index?(ami_launch_index)
        content.ami_launch_index == ami_launch_index
      end

      def has_user_data?(user_data)
        describe_attribute({attribute: 'userData'}).user_data.value == user_data
      end

      def has_key_name?(key_name)
        content.key_name == key_name
      end

      def has_image_id?(image_id)
        content.image_id == image_id
      end

      def has_instance_type?(instance_type)
        content.instance_type == instance_type
      end

      def has_source_dest_checking_disabled?
        not content.source_dest_check
      end

      def has_api_termination_disabled?
        content.describe_attribute({attribute: 'disableApiTermination'}).disable_api_termination.value
      end

      def has_elastic_ip?
        not content.public_ip_address.empty?
      end

      def has_public_ip?(public_ip_address)
        content.public_ip_address == public_ip_address
      end

      def has_kernel_id?(kernel_id)
        content.kernel_id == kernel_id
      end

      def has_public_subnet?
        instance_subnet = AWS::EC2.new.subnets[content.subnet_id]
        instance_subnet.route_table.routes.each do |route|
          if !route.internet_gateway.nil? && route.internet_gateway.exists?
            return true
          end
        end
        false
      end

      def public_ip_address
        content.public_ip_address
      end

      def subnet_id
        content.subnet_id
      end

      def to_s
        "EC2 instance: #{instance_id}"
      end
    end

    #this is how the resource is called out in a spec
    def ec2_instance(instance_id, region='us-east-1')
      EC2Instance.new(instance_id, region)
    end

  end
end

require 'aws-sdk-v1'
require 'serverspec'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class EC2Instance < Base
      include SecurityGroups

      def initialize(instance_id)
        @instance_id = instance_id
      end

      def content
        AWS::EC2.new.instances[@instance_id]
      end

      #hmmm is serverspec already messing with method_missing? maybe just fwd anything to ec2instance?
      def lauch_time
        content.launch_time
      end

      def is_ebs_optimized?
        content.ebs_optimized
      end

      def is_api_termination_disabled?
        content.api_termination_disabled?
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
        content.ebs_optimized?
      end

      def is_xen_hypervisor?
        content.hypervisor == :xen
      end

      def is_oracle_vm_hypervisor?
        content.hypervisor == :ovm
      end

      def is_stop_shutdown_behavior?
        content.instance_initiated_shutdown_behavior == 'stop'
      end

      def is_termination_shutdown_behavior?
        content.instance_initiated_shutdown_behavior == 'terminate'
      end

      def is_monitoring_disabled?
        content.monitoring == :disabled
      end

      def is_monitoring_enabled?
        content.monitoring == :enabled
      end

      def is_monitoring_pending?
        content.monitoring == :pending
      end

      # def method_missing(sym, *args, &block)
      #   @ec2_instance.send sym, *args, &block
      # end

      def has_owner_id(owner_id)
        content.owner_id == owner_id
      end

      def has_platform(platform)
        content.platform == platform
      end

      def has_iam_instance_profile_arn?(iam_instance_profile_arn)
        content.iam_instance_profile_arn == iam_instance_profile_arn
      end

      def has_iam_instance_profile_id?(iam_instance_profile_id)
        content.iam_instance_profile_id == iam_instance_profile_id
      end

      def has_dns_name?(dns_name)
        content.dns_name == dns_name
      end

      def has_ami_launch_index?(ami_launch_index)
        content.ami_launch_index == ami_launch_index
      end

      def has_user_data?(user_data)
        content.user_data == user_data
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
        content.api_termination_disabled?
      end

      def has_elastic_ip?
        content.has_elastic_ip?
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
        "EC2 instance: #{}"
      end
    end

    #this is how the resource is called out in a spec
    def ec2_instance(instance_id)
      EC2Instance.new(instance_id)
    end

  end
end

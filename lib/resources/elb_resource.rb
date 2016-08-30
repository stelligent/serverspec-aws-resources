require 'aws-sdk-v1'
require 'serverspec'
require 'set'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class ELB < Base
      include SecurityGroups

      def initialize(elb_name)
        @elb_name = elb_name
        @elb = AWS::ELB.new.load_balancers[elb_name]
        @elb_attributes = AWS::ELB.new.client.describe_load_balancer_attributes(load_balancer_name: content.name)
      end

      def has_scheme?(scheme)
        content.scheme == scheme
      end

      def has_connection_draining_enabled?
        actual_connection_draining_enabled = attributes.data[:load_balancer_attributes][:connection_draining][:enabled]
        actual_connection_draining_enabled == true
      end

      def has_connection_draining_timeout?(timeout_seconds)
        actual_connection_draining_timeout = attributes.data[:load_balancer_attributes][:connection_draining][:timeout]
        actual_connection_draining_timeout == timeout_seconds
      end

      def has_cross_zone_load_balancing_enabled?
        actual_cross_zone_load_balancing_enabled = attributes.data[:load_balancer_attributes][:cross_zone_load_balancing][:enabled]
        actual_cross_zone_load_balancing_enabled == true
      end

      def has_access_logging_enabled?(expected_value)
        actual_access_logging_enabled = attributes.data[:load_balancer_attributes][:access_log][:enabled]
        actual_access_logging_enabled == expected_value
      end

      def has_access_logging_emit_interval?(emit_interval)
        actual_access_logging_emit_interval = attributes.data[:load_balancer_attributes][:access_log][:emit_interval]
        actual_access_logging_emit_interval == emit_interval
      end

      def has_access_logging_valid_s3_bucket?
        actual_access_logging_s3_bucket = attributes.data[:load_balancer_attributes][:access_log][:s3_bucket_name]
        s3 = AWS::S3.new
        s3.buckets[actual_access_logging_s3_bucket].exists?
      end

      def has_availability_zone_names?(availability_zone_names)
        puts "fOO: #{content.availability_zone_names.class}"
        Set.new(content.availability_zone_names) == Set.new(availability_zone_names)
      end

      def has_number_of_availability_zones?(expected_number_of_availability_zones)
        az_array = []
        content.availability_zones.each do |az|
          az_array << az
        end
        az_array.size == expected_number_of_availability_zones
      end

      def has_number_of_security_groups?(expected_number_of_security_groups)
        sg_array = []
        content.security_groups.each do |sg|
          sg_array << sg
        end
        sg_array.size == expected_number_of_security_groups
      end

      def has_subnet_ids?(subnet_ids)
        Set.new(content.subnet_ids) == Set.new(subnet_ids)
      end

      def has_canonical_hosted_zone_name?(canonical_hosted_zone_name)
        content.canonical_hosted_zone_name == canonical_hosted_zone_name
      end

      def has_dns_name?(dns_name)
        content.dns_name == dns_name
      end

      def has_health_check_healthy_threshold?(healthy_threshold)
        content.health_check[:healthy_threshold] == healthy_threshold
      end

      def has_health_check_unhealthy_threshold?(unhealthy_threshold)
        content.health_check[:unhealthy_threshold] == unhealthy_threshold
      end

      def has_health_check_interval?(interval)
        content.health_check[:interval] == interval
      end

      def has_health_check_timeout?(timeout)
        content.health_check[:timeout] == timeout
      end

      def has_health_check_target?(target)
        content.health_check[:target] == target
      end

      def has_lb_cookie_stickiness_policy?
        !content.policy_descriptions[:lb_cookie_stickiness_policies].empty?
      end

      def has_lb_cookie_stickiness_policy_cookie_name?(name)
        content.lb_cookie_stickiness_policies[name]
      end

      def has_app_cookie_stickiness_policy?
        !content.policy_descriptions[:app_cookie_stickiness_policies].empty?
      end

      #cookie_name?????
      def has_app_cookie_stickiness_policy?(name)
        content.app_cookie_stickiness_policies[name]
      end

      def has_idle_timeout?(expected_idle_timeout)
        attributes.data[:load_balancer_attributes][:connection_settings][:idle_timeout].to_s == expected_idle_timeout.to_s
      end

      def has_listener?(expected_listener)
        actual_listener = content.listeners[expected_listener[:port]]
        puts expected_listener

        return false if actual_listener == nil

        actual_listener_map = {
            :port => actual_listener.port.to_s,
            :protocol => actual_listener.protocol.to_s,
            :instance_protocol => actual_listener.instance_protocol.to_s,
            :instance_port => actual_listener.instance_port.to_s
        }
        puts actual_listener_map
        actual_listener_map == expected_listener
      end

      def has_number_of_listeners?(number)
        content.listeners.enum.inject(0) { |cnt, listener| cnt + 1 } == number
      end

      def content
        @elb
      end

      def attributes
        @elb_attributes
      end

      def to_s
        "Elastic Load Balancer: #{@elb_name}"
      end


      #look for the sg too
    end

    #this is how the resource is called out in a spec
    def elb(elb_name)
      ELB.new(elb_name)
    end

  end
end

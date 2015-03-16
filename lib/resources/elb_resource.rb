require 'aws-sdk'
require 'serverspec'
require 'set'

module Serverspec
  module Type

    class ELB < Base

      def initialize(elb_name)
        @elb_name = elb_name
        @elb = AWS::ELB.new.load_balancers[elb_name]
      end


      def has_scheme?(scheme)
        content.scheme == scheme
      end

      def has_availability_zone_names?(availability_zone_names)
        Set.new(content.availability_zone_names) == Set.new(availability_zone_names)
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

      def has_health_check_healthy_threshold(healthy_threshold)
        content.health_check[:healthy_threshold] == healthy_threshold
      end

      def has_health_check_unhealthy_threshold(unhealthy_threshold)
        content.health_check[:unhealthy_threshold] == unhealthy_threshold
      end

      def has_health_check_interval(interval)
        content.health_check[:interval] == interval
      end

      def has_health_check_timeout(timeout)
        content.health_check[:timeout] == timeout
      end

      def has_health_check_target(target)
        content.health_check[:target] == target
      end

      def has_lb_cookie_stickiness_policy_cookie_name?(name)
        content.lb_cookie_stickiness_policies[name]
      end

      #cookie_name?????
      def has_app_cookie_stickiness_policy?(name)
        content.app_cookie_stickiness_policies[name]
      end

      def has_listener?(expected_listener)
        actual_listener = content.listeners[listener[:port]]
        return false if actual_listener == nil

        acutal_listener_map = {
          :server_certificate => actual_listener.server_certificate.to_s,
          :port => actual_listener.port,
          :protocol => actual_listener.protocol,
          :instance_protocol => actual_listener.instance_protocol,
          :instance_port => actual_listener.instance_port
        }
        actual_listener_map == expected_listener
      end

      def content
        @elb
      end

      def to_s
        "Elastic Load Balancer: #{}"
      end
    end

    #this is how the resource is called out in a spec
    def elb(elb_name)
      ELB.new(elb_name)
    end

  end
end

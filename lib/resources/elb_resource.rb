require 'aws-sdk'
require 'serverspec'
require 'set'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class ELB < Base
      include SecurityGroups

      def initialize(elb_name, region)
        @elb_name = elb_name
        @region = region
        client = Aws::ElasticLoadBalancing::Client.new(region: @region)
        @elb = client.describe_load_balancers({load_balancer_names: [elb_name]}).load_balancer_descriptions[0]
        @elb_attribs = client.describe_load_balancer_attributes({load_balancer_name: elb_name}).load_balancer_attributes
      end


      def has_scheme?(scheme)
        content.scheme == scheme
      end
      
      def has_connection_draining_enabled?
        @elb_attribs.connection_draining.enabled == true
      end
    
      def has_cross_zone_load_balancing_enabled?
        @elb_attribs.cross_zone_load_balancing.enabled == true
      end

      def has_availability_zones?(availability_zones)
        content.availability_zones == availability_zones
      end
      
      def has_number_of_availability_zones?(expected_number_of_availability_zones)
        content.availability_zones.count == expected_number_of_availability_zones
      end
      
      def has_number_of_security_groups?(expected_number_of_security_groups)
        content.security_groups.count == expected_number_of_security_groups
      end

      def has_subnets?(subnets)
        content.subnets == subnets
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
        !content.policies.lb_cookie_stickiness_policies.empty?
      end
      
      def has_lb_cookie_stickiness_policy_cookie_name?(name)
        if has_lb_cookie_stickiness_policy?
          return content.policies.lb_cookie_stickiness_policies[0].policy_name == name
        else
          raise "ELB with name: #{@elb_name} has no lb cookie stickiness policy"
        end 
      end

      def has_app_cookie_stickiness_policy?
        !content.policies.app_cookie_stickiness_policies.empty?
      end
      
      def has_app_cookie_stickiness_policy?(name)
        if has_app_cookie_stickiness_policy?
          return content.policies.app_cookie_stickiness_policies[0].policy_name == name
        else
          raise "ELB with name: #{@elb_name} has no app cookie stickiness policy"
        end 
      end

      def has_idle_timeout?(expected_idle_timeout)
        @elb_attribs.connection_settings.idle_timeout.to_s == expected_idle_timeout.to_s
      end

      def has_listener?(expected_listener)
        listener_description = content.listener_descriptions.find { |desc| desc.listener.load_balancer_port == expected_listener[:port] }
        return false if listener_description == nil
        actual_listener = listener_description.listener

        actual_listener_map = {
          :port => actual_listener.load_balancer_port.to_s,
          :protocol => actual_listener.protocol.to_s,
          :instance_protocol => actual_listener.instance_protocol.to_s,
          :instance_port => actual_listener.instance_port.to_s
        }
        
        actual_listener_map == expected_listener
      end

      def has_number_of_listeners?(number)
        content.listener_descriptions.count == number
      end

      #TODO: Include Methods to check ELB security groups

      def content
        @elb
      end

      def to_s
        "Elastic Load Balancer: #{@elb_name}"
      end

    end

    #this is how the resource is called out in a spec
    def elb(elb_name, region='us-east-1')
      ELB.new(elb_name, region)
    end

  end
end

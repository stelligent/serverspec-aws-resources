


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

    class VPNGateway < Base

      def initialize(vgw)
        @vgw = vgw
      end

      def has_name?(name)
        @vgw.tags['Name'] == name
      end
    end

    class Subnets < Base

      def initialize(subnets)
        @subnets = subnets
      end

      def has_cidr_blocks?(expected_cidr_blocks)
        actual_cidr_blocks = @subnets.map { |subnet| subnet.cidr_block }
        actual_cidr_blocks - expected_cidr_blocks == [] and expected_cidr_blocks - actual_cidr_blocks == []
      end

      def size
        @subnets.size
      end
    end

    class VPC < Base

      def initialize(vpc_id)
        raise 'must set a vpc_id' if vpc_id.nil?
        @vpc_id = vpc_id
      end

      def content
        @vpc = AWS::EC2.new.vpcs[@vpc_id]
        raise "#{@vpc_id} does not exist" unless @vpc.exists?
        @vpc
      end

      def to_s
        "vpc: #{@vpc_id}"
      end

      def default_tenancy?
        content.instance_tenancy == :default
      end

      def dedicated_tenancy?
        not default_tenancy?
      end

      def available?
        content.state == :available
      end

      def pending?
        content.state == :pending
      end

      def cidr_block
        content.cidr_block
      end

      def attached_to_an_internet_gateway?
        not content.internet_gateway.nil?
      end

      def attached_to_an_virtual_private_gateway?
        not content.vpn_gateway.nil?
      end

      def virtual_private_gateway
        raise 'there is no virtual private gateway attached to vpc' unless attached_to_an_virtual_private_gateway?
        VPNGateway.new content.vpn_gateway
      end

      def dhcp_options
        content.dhcp_options.configuration
      end

      def size
        compute_subnets.size
      end

      def subnets
        Subnets.new compute_subnets
      end

      def public_subnets
        Subnets.new compute_public_subnets
      end

      def natted_subnets
        Subnets.new compute_natted_subnets
      end

      def private_subnets
        Subnets.new compute_private_subnets
      end

      def nats
        nat_instances.map { |nat| EC2Instance.new(nat) }
      end

      private

      def compute_subnets
        subnet_arr = []
        content.subnets.each { |subnet| subnet_arr << subnet }
        subnet_arr
      end

      def compute_public_subnets
        subnet_arr = []
        compute_subnets.each { |subnet| subnet_arr << subnet if has_route_to_igw(subnet) }
        subnet_arr
      end

      def compute_natted_subnets
        subnet_arr = []
        compute_subnets.each { |subnet| subnet_arr << subnet if has_route_to_nat(subnet) }
        subnet_arr
      end

      #anything that isnt natted or igw
      #could be only local to vpc, or connected via a peering or vpn
      def compute_private_subnets
        subnet_ids(compute_subnets) - subnet_ids(compute_public_subnets) - subnet_ids(compute_natted_subnets)
      end

      def subnet_ids(subnets)
        subnets.map { |subnet| subnet.subnet_id }
      end

      def has_route_to_igw(subnet)
        route_table_for_subnet(subnet).routes.each do |route|
          if not route.internet_gateway.nil? and route.internet_gateway.exists?
            return true
          end
        end
        false
      end

      def has_route_to_nat(subnet)
        route_table_for_subnet(subnet).routes.each do |route|
          unless route.instance.nil?
            return true if nats_ids.include? route.instance.id
          end
        end
        false
      end

      def route_table_for_subnet(subnet)

        content.route_tables.each do |route_table|
          route_table.subnets.each do |subnet_iter|
            if subnet_iter.subnet_id == subnet.subnet_id
              return route_table
            end
          end
        end
        raise 'should never fall through to here since all subnets have a route table'
      end

      def nat_instances
        content.instances.select { |instance| instance.image.name.match /^amzn-ami-vpc-nat.*/ }
      end


      def nats_ids
        nat_instances.map { |instance| instance.id }
      end

    end

    #this is how the resource is called out in a spec
    def vpc(vpc_id)
      VPC.new(vpc_id)
    end
  end
end



include Serverspec::Type
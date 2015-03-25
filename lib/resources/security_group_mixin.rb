require 'set'

module Serverspec
  module Type
    module SecurityGroups
      def has_ingress_rules?(expected_ingress_rules)
        # actual_ingress_rules = Set.new
        # content.security_groups.each do |sg|
        #   sg.ingress_ip_permissions.each do |perm|
        #     if perm.groups == []
        #       actual_ingress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :ip_ranges=>perm.ip_ranges}
        #     else
        #       actual_ingress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :groups=>perm.groups}
        #     end
        #   end
        # end
        #
        # actual_ingress_rules.should == Set.new(expected_ingress_rules)
        has_sg_rules(expected_ingress_rules) { |sg| sg.ingress_ip_permissions }

      end

      #this is duplicative
      def has_egress_rules?(expected_egress_rules)
        # actual_egress_rules = Set.new
        # content.security_groups.each do |sg|
        #   sg.egress_ip_permissions.each do |perm|
        #     if perm.groups == []
        #       actual_egress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :ip_ranges=>perm.ip_ranges}
        #     else
        #       actual_egress_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :groups=>perm.groups}
        #     end
        #   end
        # end
        #
        # actual_egress_rules.should == Set.new(expected_egress_rules)
        has_sg_rules(expected_egress_rules) { |sg| sg.egress_ip_permissions }
      end

      def has_sg_rules(expected_rules) #&permissionw
        actual_rules = Set.new
        content.security_groups.each do |sg|
          yield(sg).each do |perm|
            if perm.groups == []
              actual_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :ip_ranges=>perm.ip_ranges}
            else
              actual_rules << {:port_range=>perm.port_range, :protocol=>perm.protocol, :groups=>perm.groups}
            end
          end
        end

        actual_rules.should == Set.new(expected_rules)
      end
    end
  end
end

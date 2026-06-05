module Virti
  module Acl
    module Patches
      module AssignmentsControllerPatch
        def create
          return render json: { error: 'Permission denied' }, status: :forbidden unless virti_acl_assignment_allowed?

          super
        end

        private

        def virti_acl_assignment_allowed?
          Virti::Acl::AssignmentPolicy.new(user: Current.user, account: Current.account).assign?
        end
      end
    end
  end
end

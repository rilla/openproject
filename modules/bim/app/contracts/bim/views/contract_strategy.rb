module ::Bim
  module Views
    class ContractStrategy < ::BaseContract
      validate :manageable

      private

      def manageable
        return if model.query.blank?

        errors.add(:base, :error_unauthorized) unless view_permissions?
      end

      def view_permissions?
        return false unless user_allowed_on_view?(:view_ifc_models)
        return false unless user_allowed_on_view?(:save_bcf_queries)
        if model.query.is_public && !user_allowed_on_view?(:manage_public_bcf_queries)
          return false
        end

        true
      end

      def user_allowed_on_view?(permission)
        user.allowed_to?(permission, model.query.project, global: model.query.project.nil?)
      end
    end
  end
end

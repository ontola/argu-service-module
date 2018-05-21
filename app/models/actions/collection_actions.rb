# frozen_string_literal: true

module Actions
  class CollectionActions < Base
    include Pundit
    include 'VotesHelper'.constantize if 'VotesHelper'.safe_constantize

    define_actions %i[new create]

    private

    def association
      @association ||= association_class.to_s.tableize
    end

    def association_class
      resource.association_class
    end

    def new_action
      return unless resource.part_of && policy(resource.part_of).try(:create_child?, association)
      action_item(
        :new,
        target: new_entrypoint,
        result: association_class,
        type: [NS::ARGU["New#{association_class}"], NS::SCHEMA[:NewAction]]
      )
    end

    def new_entrypoint
      entry_point_item(
        :new,
        label: label,
        image: image,
        url: new_url,
        http_method: :get
      )
    end

    def new_url
      col_iri = resource.iri(only_path: true)
      query = col_iri.query
      col_iri.query = nil
      iri = RDF::URI(expand_uri_template('new_iri', collection_iri: col_iri))
      iri.query = query if query.present?
      iri
    end

    def create_action
      return unless resource.part_of && policy(resource.part_of).try(:create_child?, association)
      action_item(
        :create,
        target: create_entrypoint,
        result: association_class,
        type: [NS::ARGU["Create#{association_class}"], NS::ARGU[:CreateAction]]
      )
    end

    def create_entrypoint
      entry_point_item(
        :create,
        label: label,
        image: image,
        url: create_url,
        http_method: :post
      )
    end

    def create_url
      return resource.parent_view_iri if paged_resource?
      resource.iri
    end

    def filtered_resource?
      resource.is_a?(Collection) && resource.filter.present?
    end

    def image
      return 'fa-plus' unless filtered_resource? && resource.filter['option'].present?
      "fa-#{icon_for_side(resource.filter['option'])}"
    end

    def label
      return I18n.t("#{association}.type_new") unless filtered_resource? && association_class == Vote
      I18n.t("#{association}.type.#{resource.filter['option']}")
    end

    def paged_resource?
      resource.is_a?(Collection) && resource.pagination && resource.page.present?
    end

    def resource_path_iri
      return super unless paged_resource?

      self_without_page = resource.parent_view_iri
      self_without_page.host = nil
      self_without_page.scheme = nil
      self_without_page
    end
  end
end

# frozen_string_literal: true

class CollectionActions < ActionList
  include Pundit

  cattr_accessor :defined_actions
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
      label: I18n.t("#{association}.type_new"),
      image: 'fa-plus',
      url: new_url,
      http_method: :get
    )
  end

  def new_url
    expand_uri_template('new_iri', collection_iri: resource.iri)
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
      label: I18n.t("#{association}.type_new"),
      image: 'fa-plus',
      url: create_url,
      http_method: :post
    )
  end

  def create_url
    return resource.parent_view_iri if paged_resource?
    resource.iri
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

# frozen_string_literal: true

class CollectionActions < ActionList
  include Pundit

  cattr_accessor :defined_actions
  define_actions %i[new create]

  private

  def association
    @association ||= resource.association_class.to_s.tableize
  end

  def new_action
    return unless resource.part_of && policy(resource.part_of).try(:create_child?, association)
    action_item(
      :new,
      target: new_entrypoint,
      type: [NS::ARGU["New#{resource.association_class}"], NS::SCHEMA[:NewAction]]
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
      type: [NS::ARGU["Create#{resource.association_class}"], NS::ARGU[:CreateAction]]
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
    resource.iri
  end
end

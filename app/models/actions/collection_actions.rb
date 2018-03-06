# frozen_string_literal: true

class CollectionActions < ActionList
  cattr_accessor :defined_actions
  define_actions %i[new]

  private

  def new_action
    action_item(
      :new,
      target: new_entrypoint,
      type: NS::SCHEMA[:CreateAction]
    )
  end

  def new_entrypoint
    entry_point_item(
      :new,
      label: I18n.t("#{resource.association_class.to_s.tableize}.type_new"),
      image: 'fa-plus',
      url: new_url,
      http_method: :get
    )
  end

  def new_url
    u = URI.parse(resource.iri)
    u.path += '/new'
    RDF::URI(u.to_s)
  end
end

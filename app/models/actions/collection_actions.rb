# frozen_string_literal: true

class CollectionActions < ActionList
  include Pundit

  cattr_accessor :defined_actions
  define_actions %i[new]

  private

  def association
    @association ||= resource.association_class.to_s.tableize
  end

  def new_action
    return unless policy(resource.part_of).try(:create_child?, association)
    action_item(
      :new,
      target: new_entrypoint,
      type: NS::SCHEMA[:CreateAction]
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
    u = URI.parse(resource.iri)
    u.path += '/new'
    RDF::URI(u.to_s)
  end
end

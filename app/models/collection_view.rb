# frozen_string_literal: true

class CollectionView < RailsLD::CollectionView
  def preload_singular_association(members, key, reflection, _includes)
    super
    return unless reflection.klass <= Edge && key != :root
    members.each { |member| member.send(key).association(:root).target = member.root }
  end
end

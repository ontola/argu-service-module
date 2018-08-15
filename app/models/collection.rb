# frozen_string_literal: true

require_relative '../../lib/rails_ld.rb'
require_relative '../../lib/rails_ld/collection.rb'

class Collection < RailsLD::Collection
  include ApplicationModel
  include Pundit
  include Ldable
  include Iriable

  attr_accessor :user_context, :parent_uri_template_canonical, :parent_uri_template_opts
  attr_writer :title, :parent_uri_template

  alias pundit_user user_context

  def actions(user_context)
    association_class
      .try(:actions_class!)
      &.new(resource: self, user_context: user_context)
      &.actions
  end

  def action(user_context, tag)
    actions(user_context).find { |a| a.tag == tag }
  end

  def association_base
    @association_base ||= policy_scope(filtered_association)
  end

  def canonical_iri(only_path: false)
    iri(canonical: true, only_path: only_path)
  end

  def inspect
    "#<#{association_class}Collection #{iri} filters=#{filter || []}>"
  end

  def self.iri
    [super, NS::AS['Collection']]
  end

  def iri(canonical: false, only_path: false)
    RDF::URI(
      expand_uri_template(
        parent_uri_template(canonical),
        iri_opts(canonical).merge(only_path: only_path)
      )
    )
  end
  alias id iri

  def iri_opts(canonical = false)
    opts = {
      parent_iri: canonical ? parent&.canonical_iri(only_path: true) : parent&.iri_path
    }
    opts.delete(:parent_iri) if opts[:parent_iri].blank?
    opts['filter%5B%5D'] = filter.map { |key, value| "#{key}=#{value}" } if filtered?
    opts.merge(parent_uri_template_opts || {})
  end

  def iri_template
    @iri_template ||= URITemplate.new("#{iri}{?filter%5B%5D,page,page_size,type,before,sort%5B%5D}")
  end

  def total_count
    @total_count ||= count_from_cache_column || super
  end

  private

  def count_from_cache_column
    return if filtered?
    parent.children_count(counter_cache_column) if counter_cache_column
  end

  def counter_cache_column
    key = association.to_s.starts_with?('active_') && association.to_s[7..-1]
    opts = association_class.try(:counter_cache_options)
    @counter_cache_column ||= key if key && opts && (opts == true || opts.keys.map(&:to_s).include?(key))
  end

  def new_child_values
    super.merge(
      parent_uri_template_canonical: parent_uri_template_canonical,
      parent_uri_template_opts: parent_uri_template_opts,
      user_context: user_context,
      parent_uri_template: parent_uri_template
    )
  end

  def parent_uri_template(canonical = false)
    if canonical
      @parent_uri_template_canonical || "#{association_class.to_s.tableize}_collection_canonical"
    else
      @parent_uri_template || "#{association_class.to_s.tableize}_collection_iri"
    end
  end

  def policy_scope(scope)
    policy_scope = PolicyFinder.new(scope).scope
    policy_scope ? policy_scope.new(pundit_user, scope).resolve : scope
  end
end

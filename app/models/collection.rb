# frozen_string_literal: true

require_relative '../../lib/rails_ld.rb'
require_relative '../../lib/rails_ld/collection.rb'

class Collection < RailsLD::Collection
  include ApplicationModel
  include Pundit
  include Ldable
  include Iriable

  attr_accessor :user_context, :parent_uri_template, :parent_uri_template_canonical, :parent_uri_template_opts
  attr_writer :title

  alias id iri
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

  def inspect
    "#<#{association_class}Collection #{iri} filters=#{filter || []}>"
  end

  def self.iri
    [super, NS::AS['Collection']]
  end

  def iri_opts
    opts = {}
    iri_opts_add(opts, :parent_iri, parent&.iri_path)
    iri_opts_add(opts, :type, type)
    iri_opts_add(opts, :page_size, page_size)
    iri_opts_add(opts, :'filter%5B%5D', filter_iri_opts)
    iri_opts_add(opts, :'sort%5B%5D', sort_iri_opts)
    opts.merge(parent_uri_template_opts || {})
  end

  def iri_template
    @iri_template ||=
      URITemplate.new("#{iri.to_s.split('?').first}{?filter%5B%5D,page,page_size,type,before,sort%5B%5D}")
  end

  def total_count
    @total_count ||= count_from_cache_column || super
  end

  private

  def canonical_iri_opts
    opts = iri_opts
    opts[:parent_iri] = parent&.canonical_iri(only_path: true)
    opts
  end

  def canonical_iri_template_name
    @parent_uri_template_canonical || "#{association_class.to_s.tableize}_collection_canonical"
  end

  def count_from_cache_column
    return if filtered?
    parent.children_count(counter_cache_column) if counter_cache_column
  end

  def counter_cache_column
    key = association.to_s.starts_with?('active_') && association.to_s[7..-1]
    opts = association_class.try(:counter_cache_options)
    @counter_cache_column ||= key if key && opts && (opts == true || opts.keys.map(&:to_s).include?(key))
  end

  def filter_iri_opts
    filter&.map { |key, value| "#{key}=#{value}" }
  end

  def iri_opts_add(opts, key, value)
    opts[key] = value if value
  end

  def iri_template_name
    @parent_uri_template || "#{association_class.to_s.tableize}_collection_iri"
  end

  def new_child_values
    super.merge(
      parent_uri_template_canonical: parent_uri_template_canonical,
      parent_uri_template_opts: parent_uri_template_opts,
      user_context: user_context,
      parent_uri_template: parent_uri_template
    )
  end

  def policy_scope(scope)
    policy_scope = PolicyFinder.new(scope).scope
    policy_scope ? policy_scope.new(pundit_user, scope).resolve : scope
  end

  def sort_iri_opts
    sort&.map { |key, value| "#{key}=#{value}" }
  end
end

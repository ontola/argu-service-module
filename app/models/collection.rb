# frozen_string_literal: true

require_relative '../../lib/rails_ld.rb'
require_relative '../../lib/rails_ld/collection.rb'

class Collection < RailsLD::Collection
  include ApplicationModel
  include Pundit
  include RailsLD::Model
  include Collection::CounterCache

  attr_accessor :user_context, :parent_uri_template, :parent_uri_template_canonical
  attr_writer :association_base, :parent_uri_template_opts, :policy
  delegate :root_id, to: :parent

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

  def clear_total_count
    parent&.reload
    @total_count = nil
  end

  def inspect
    "#<#{association_class}Collection #{iri} filters=#{filter || []}>"
  end

  def self.iri
    [super, NS::AS['Collection']]
  end

  def iri_opts # rubocop:disable Lint/UnneededDisable, Metrics/AbcSize
    opts = {}
    iri_opts_add(opts, :parent_iri, parent&.iri_path)
    iri_opts_add(opts, :display, display) if display
    iri_opts_add(opts, :type, type) if type&.to_sym != default_type
    iri_opts_add(opts, :page_size, page_size)
    iri_opts_add(opts, :'filter%5B%5D', filter_iri_opts)
    iri_opts_add(opts, :'sort%5B%5D', sort_iri_opts)
    opts.merge(parent_uri_template_opts || {})
  end

  def iri_template
    @iri_template ||=
      URITemplate.new("#{iri_path.split('?').first}{?display,filter%5B%5D,page,page_size,type,before,sort%5B%5D}")
  end

  def policy
    @policy ||= PolicyFinder.new(association_class).policy
  end

  private

  def canonical_iri_opts
    opts = iri_opts
    opts[:parent_iri] = parent&.canonical_iri_path
    opts
  end

  def canonical_iri_template_name
    return @canonical_iri_template_name if @canonical_iri_template_name
    canonical_name ||= @parent_uri_template_canonical || "#{association_class.to_s.tableize}_collection_canonical"
    @canonical_iri_template_name = uri_template(canonical_name) ? canonical_name : iri_template_name
  end

  def filter_iri_opts
    filter&.map { |key, value| "#{key}=#{value}" }
  end

  def iri_opts_add(opts, key, value)
    opts[key] = value if value.present?
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

  def parent_uri_template_opts
    @parent_uri_template_opts.respond_to?(:call) ? @parent_uri_template_opts.call(parent) : @parent_uri_template_opts
  end

  def policy_scope(scope)
    policy_scope = policy && policy::Scope
    policy_scope ? policy_scope.new(pundit_user, scope).resolve : scope
  end

  def sort_iri_opts
    sort&.map { |key, value| "#{key}=#{value}" }
  end
end

# frozen_string_literal: true

require 'active_response/responders/js'

class JSResponder < ActiveResponse::Responders::JS
  respond_to :js

  def form(**opts)
    js_view?(opts[:view]) ? render_view(opts) : replace_view(opts)
  end

  def redirect(**opts)
    controller.flash[flash_key(opts)] = opts[flash_key(opts)] if flash_key(opts)
    controller.render 'turbolinks_redirect', locals: {location: opts[:location]}
  end

  private

  def flash_key(opts)
    (opts.keys & %i[notice alert]).first
  end

  def js_view?(view)
    lookup_template(view, 'js').present?
  end

  def lookup_template(view, format)
    if view.to_s.include?('/')
      resolve_template(view, format)
    else
      resolve_template("#{controller.controller_path}/#{view}", format) ||
        resolve_template("application/#{view}", format)
    end
  end

  def render_view(opts)
    controller.render(
      "#{opts[:view]}.js",
      layout: false,
      locals: opts[:locals].merge(template: lookup_template(opts[:view], 'html'))
    )
  end

  def replace_view(opts)
    controller.render(
      'container_replace',
      locals: {view: lookup_template(opts[:view], :html), locals: opts[:locals]}
    )
  end

  def resolve_template(view, format)
    name = "#{view}.#{format}"
    name if controller.lookup_context.exists?(name)
  end
end

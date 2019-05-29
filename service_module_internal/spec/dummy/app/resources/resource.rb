# frozen_string_literal: true

class Resource < ActiveResourceModel
  self.site = URI(service_url(:argu))
end

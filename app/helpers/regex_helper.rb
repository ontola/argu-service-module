# frozen_string_literal: true

module RegexHelper
  SINGLE_EMAIL = /
  #{RFC822::Patterns::LOCAL_PT}
    \x40
    (?:(?:#{URI::REGEXP::PATTERN::DOMLABEL}\.)+#{URI::REGEXP::PATTERN::TOPLABEL}\.?)+#{RFC822::Patterns::ATOM}
  /x.freeze
  EMAIL = /\A#{SINGLE_EMAIL}\z/.freeze
end

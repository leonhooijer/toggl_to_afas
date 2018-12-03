# frozen_string_literal: true

require_relative "in_site/click_bot"
require_relative "in_site/time_entry"

module Afas
  module InSite
    URL = "https://74002.afasinsite.nl"
    USERNAME = ENV.fetch("AFAS_USERNAME").freeze
    PASSWORD = ENV.fetch("AFAS_PASSWORD").freeze
  end
end

module Afas
  module InSite
    URL = 'https://74002.afasinsite.nl'.freeze
    USERNAME = ENV.fetch('AFAS_USERNAME').freeze
    PASSWORD = ENV.fetch('AFAS_PASSWORD').freeze
  end
end

module Afas
  module InSite
    class SignIn
      def self.exec(session)
        return unless session.has_content?('Inloggen')
        session.fill_in 'Gebruikersnaam', with: Afas::InSite::USERNAME
        session.fill_in 'Wachtwoord', with: Afas::InSite::PASSWORD
        session.click_on 'Inloggen'
      end
    end
  end
end
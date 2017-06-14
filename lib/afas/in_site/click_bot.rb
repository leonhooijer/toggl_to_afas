module Afas
  module InSite
    class ClickBot
      attr_accessor :session

      def initialize(session)
        @session = session
      end

      def fill_in_working_hours(time_entry)
        session.click_on 'Projecten', match: :first
        session.find('[title="Uren boeken"]').click

        session.fill_in 'Jaar', with: time_entry.year
        session.fill_in 'Periode', with: time_entry.week
        session.click_on 'Selecteren'

        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_DaTi_MainControl', with: time_entry.date.strftime('%d-%m-%Y')
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_PrId_MainControl', with: time_entry.project
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_VaIt_MainControl', with: time_entry.type_of_work
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_BiId_MainControl', with: time_entry.code
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_QuUn_MainControl', with: time_entry.duration
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_StId_MainControl', with: time_entry.type_of_hours
        session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_Ds_MainControl',   with: time_entry.description

        sleep 3

        if session.find('#P_C_W_Entry_Footer_LAY_PtPrj_Ds_MainControl').value == ''
          raise 'Project description field was not updated.'
        end

        session.find('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0').click

        session.has_content?('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0.webbutton.webbutton-text-image-primary.cursordefault[disabled]')
      end

      def sign_in
        session.visit Afas::InSite::URL
        return unless session.has_content?('Inloggen')
        session.fill_in 'Gebruikersnaam', with: Afas::InSite::USERNAME
        session.fill_in 'Wachtwoord', with: Afas::InSite::PASSWORD
        session.click_on 'Inloggen'
      end
    end
  end
end

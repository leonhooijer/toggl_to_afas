module Afas
  module InSite
    class ClickBot
      attr_accessor :session

      def initialize(session)
        @session = session
      end

      def open_working_hours_form
        session.click_on 'Projecten', match: :first
        session.find('[title="Uren boeken"]').click
      end

      def select_working_hours_period(year, week)
        session.fill_in 'Window_0_Entry_Selection_Selection_Year', with: year
        session.fill_in 'Window_0_Entry_Selection_Selection_PeId', with: week
        session.click_on 'Selecteren'
        session.find('#Window_0_Entry_Detail_Detail_DaTi')
      end

      def add_time_entry
        session.find('#P_C_W_Entry_Detail_E3_ButtonEntryWebPart_AddRow_E3').click
      end

      def remove_time_entry
        session.find('#P_C_W_Entry_Detail_E5_ButtonEntryWebPart_DeleteRow_E5').click
      end

      def fill_in_time_entry(time_entry)
        session.fill_in 'Window_0_Entry_Detail_Detail_DaTi', with: time_entry.date.strftime('%d-%m-%Y')
        fill_in_date(time_entry.date.strftime('%d-%m-%Y'))
        session.fill_in 'Window_0_Entry_Detail_Detail_PrId', with: time_entry.project
        session.fill_in 'Window_0_Entry_Detail_Detail_VaIt', with: time_entry.type_of_work
        session.fill_in 'Window_0_Entry_Detail_Detail_BiId', with: time_entry.code
        fill_in_duration(time_entry.duration)
        session.fill_in 'Window_0_Entry_Detail_Detail_StId', with: time_entry.type_of_hours
        session.fill_in 'Window_0_Entry_Detail_Detail_Ds',   with: time_entry.description
      end

      def fill_in_duration(duration)
        until session.find('#Window_0_Entry_Detail_Detail_QuUn').value == duration.to_s
          session.fill_in 'Window_0_Entry_Detail_Detail_QuUn', with: duration
          sleep 1
        end
      end

      def fill_in_date(date)
        until session.find('#Window_0_Entry_Detail_Detail_DaTi').value == date.to_s
          session.fill_in 'Window_0_Entry_Detail_Detail_DaTi', with: date
          sleep 1
        end
      end

      def save_time_entries
        session.find('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0').click
        sleep 3
        session.has_content?('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0[disabled]')
      end

      def project_description_updated?
        3.times do
          break if session.find('#Window_0_Entry_Footer_Detail_LAY_PtPrj_Ds').value != ''
          sleep 1
        end

        session.find('#Window_0_Entry_Footer_Detail_LAY_PtPrj_Ds').value != ''
      end

      def fill_in_working_hours(time_entries)
        entries_grouped_by_period = {}

        time_entries.each do |time_entry|
          next unless time_entry
          if entries_grouped_by_period[time_entry.year].to_h[time_entry.week]
            entries_grouped_by_period[time_entry.year].to_h[time_entry.week] << time_entry
          elsif entries_grouped_by_period[time_entry.year]
            entries_grouped_by_period[time_entry.year][time_entry.week] = [time_entry]
          else
            entries_grouped_by_period[time_entry.year] = { time_entry.week => [time_entry] }
          end
        end

        open_working_hours_form

        entries_grouped_by_period.each do |year, weeks|
          weeks.each do |week, time_entries_for_period|
            select_working_hours_period(year, week)

            time_entries_for_period.each do |time_entry|
              fill_in_time_entry(time_entry)
              raise 'Project description field was not updated.' unless project_description_updated?
              sleep 1
              add_time_entry
              sleep 1
            end

            sleep 1
            remove_time_entry
            sleep 1
            save_time_entries
            sleep 5
          end
        end
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

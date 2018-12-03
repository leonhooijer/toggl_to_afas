# frozen_string_literal: true

module Afas
  module InSite
    # Capybara click bot to enter data in Afas InSite.
    class ClickBot
      attr_accessor :session

      def initialize(session)
        @session = session
      end

      def open_working_hours_form
        session.click_on("Projecten", match: :first)
        session.find('[title="Uren boeken"]').click
      end

      def select_working_hours_period(year, week)
        session.fill_in "Window_0_Entry_Selection_Selection_Year", with: year
        session.fill_in "Window_0_Entry_Selection_Selection_PeId", with: week
        session.click_on "Selecteren"
        session.find("#Window_0_Entry_Detail_Detail_DaTi")
      end

      def fill_in_time_entries(year, week, time_entries)
        select_working_hours_period(year, week)
        time_entries.each do |time_entry|
          next if entry_exists?(time_entry)

          fill_in_time_entry(time_entry)
          raise "Project description field was not updated." unless project_description_updated?

          add_time_entry
        end
        remove_time_entry
        save_time_entries
      end

      def add_time_entry
        session.find("#P_C_W_Entry_Detail_E3_ButtonEntryWebPart_AddRow_E3").click
        sleep 1
      end

      def remove_time_entry
        session.find("#P_C_W_Entry_Detail_E5_ButtonEntryWebPart_DeleteRow_E5").click
        sleep 1
      end

      def fill_in_time_entry(time_entry)
        fill_in_field("DaTi", time_entry.afas_date)
        fill_in_field("PrId", time_entry.project)
        fill_in_field("VaIt", time_entry.type_of_work)
        fill_in_field("BiId", time_entry.code)
        fill_in_field("QuUn", time_entry.afas_duration)
        fill_in_field("StId", time_entry.type_of_hours)
        fill_in_field("Ds",   time_entry.afas_description)
      end

      def fill_in_field(field_id, value)
        until session.find("#Window_0_Entry_Detail_Detail_#{field_id}").value == value.to_s
          session.fill_in "Window_0_Entry_Detail_Detail_#{field_id}", with: value
          sleep 1
        end
      end

      def entry_exists?(time_entry)
        session.using_wait_time(0) { session.has_css?(".valuecontrol", text: "(TogglID: #{time_entry.id})") }
      end

      def save_time_entries
        session.find("#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0").click
        sleep 3
        session.has_content?("#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0[disabled]")
      end

      def project_description_updated?
        3.times do
          sleep(1) if session.find("#Window_0_Entry_Footer_Detail_LAY_PtPrj_Ds").value == ""
        end
        sleep 1
        session.find("#Window_0_Entry_Footer_Detail_LAY_PtPrj_Ds").value != ""
      end

      def fill_in_working_hours(time_entries)
        time_entries_by_year_and_week(time_entries).each do |year, weeks|
          weeks.each do |week, time_entries_for_period|
            fill_in_time_entries(year, week, time_entries_for_period)
          end
        end
      end

      def time_entries_by_year_and_week(time_entries)
        entries_grouped_by_year = time_entries.group_by(&:year)
        entries_grouped_by_year.each do |year, entries|
          entries_grouped_by_year[year] = entries.group_by(&:week)
        end
        entries_grouped_by_year
      end

      def sign_in
        return unless session.has_css?("div", class: "header", text: "Inloggen bij AFAS Online")

        fill_in_email(Afas::InSite::USERNAME)
        fill_in_password(Afas::InSite::PASSWORD)
        puts "Please enter the passcode you received through SMS:"
        fill_in_passcode(gets.chomp)
      end

      def fill_in_email(email)
        session.fill_in "Email", with: email
        session.click_on "Volgende"
      end

      def fill_in_password(password)
        session.fill_in "Password", with: password
        session.click_on "Volgende"
      end

      def fill_in_passcode(passcode)
        session.fill_in "Code", with: passcode
        session.click_on "Volgende"
      end

      def close_amber_alert
        session.first("#P_CH_W_Amber_MarkAsRead", minimum: 0, maximum: 1)&.click
      end
    end
  end
end

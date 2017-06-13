require 'capybara'
require 'json'
require 'togglv8'

Dir.glob('./lib/**/*.rb').each { |file| require file }

Capybara.default_max_wait_time = 10

session = Capybara::Session.new(:selenium)

# Read environment
toggl_api_token = ENV.fetch('TOGGL_API_TOKEN').freeze
toggl_reports_since = Time.strptime(ENV.fetch('SINCE'), "%Y-%m-%dT%H:%M:%s").to_datetime
toggl_reports_until = Time.strptime(ENV.fetch('UNTIL'), "%Y-%m-%dT%H:%M:%s").to_datetime

# Toggl
toggl_api = TogglV8::API.new(toggl_api_token)
user = toggl_api.me(all = true)
workspaces = toggl_api.my_workspaces(user)
workspace = workspaces.select { |w| w[:name] == 'De Praktijk Index' }.first

toggl_reports_api = TogglV8::ReportsV2.new(api_token: toggl_api_token)
toggl_reports_api.workspace_id = workspace['id']
toggl_records = toggl_reports_api.details(:json,
                                          since: toggl_reports_since,
                                          until: toggl_reports_until,
                                          order_desc: 'off')

toggl_records.each do |toggl_record|
  begin
    description = toggl_record["description"]
    project = toggl_record["project"]
    tags = toggl_record["tags"]
    duration = toggl_record["dur"]
    start_time = DateTime.parse(toggl_record["start"])

    seconds = duration / 1000.0
    minutes = seconds / 60.0
    hours = minutes / 60.0

    complete_hours = hours.floor
    complete_minutes = (minutes - (complete_hours * 60)).floor
    complete_seconds = (seconds - (minutes.floor * 60)).floor

    mins = ((complete_minutes / 3.0) * 5) / 100.0
    secs = ((complete_seconds / 3.0)) * 5 / 10_000.0

    afas_duration = complete_hours + mins + secs

    afas_project = /\((.*)\)/.match(project).to_a[1]
    afas_description = description

    unless afas_project
      afas_description = [project, description].reject { |d| d == '' }.join(": ")
      afas_project = 'ALG'
    end

    afas_duration -= 0.5 if project == 'Lunch'

    next unless afas_duration > 0

    afas_time_entry = Afas::InSite::TimeEntry.new(start_time.to_date,
                                          afas_project,
                                          'Wst',
                                          tags.first,
                                          (afas_duration * 20).round / 20.0,
                                          'N',
                                          afas_description)

    # Afas Insite
    session.visit Afas::InSite::URL
    Afas::InSite::SignIn.exec(session)

    # Uren openen
    session.click_on "Projecten", match: :first
    session.find('[title="Uren boeken"]').click

    # Week selecteren
    session.fill_in "Jaar", with: afas_time_entry.year
    session.fill_in "Periode", with: afas_time_entry.week
    session.click_on "Selecteren"

    # Entry invoeren
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_DaTi_MainControl', with: afas_time_entry.date.strftime("%d-%m-%Y")
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_PrId_MainControl', with: afas_time_entry.project
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_VaIt_MainControl', with: afas_time_entry.type_of_work
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_BiId_MainControl', with: afas_time_entry.code
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_QuUn_MainControl', with: afas_time_entry.duration
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_StId_MainControl', with: afas_time_entry.type_of_hours
    session.fill_in 'P_C_W_Entry_Detail_EditGrid_re_Ds_MainControl',   with: afas_time_entry.description

    sleep 3

    if session.find('#P_C_W_Entry_Footer_LAY_PtPrj_Ds_MainControl').value == ""
      raise "Project not updated"
    end

    session.find('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0').click

    session.has_content?('#P_C_W_Entry_Actions_E0_ButtonEntryWebPart_OK_E0.webbutton.webbutton-text-image-primary.cursordefault[disabled]')
  rescue => e
    puts "###############################"
    puts toggl_record
    puts afas_time_entry
    puts e.message
    puts e.backtrace
    retry
  ensure
    session.driver.quit
  end
end

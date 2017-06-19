require 'capybara'
require 'json'
require 'togglv8'

begin
  Dir.glob('./lib/**/*.rb').each { |file| require file }

  Capybara.default_max_wait_time = 10

  session = Capybara::Session.new(:selenium)

  # Read environment
  toggl_api_token = ENV.fetch('TOGGL_API_TOKEN').freeze
  toggl_reports_since = DateTime.parse(ENV.fetch('SINCE')).to_datetime
  toggl_reports_until = DateTime.parse(ENV.fetch('UNTIL')).to_datetime

  # Toggl
  toggl_api = TogglV8::API.new(toggl_api_token)
  user = toggl_api.me(all = true)
  workspaces = toggl_api.my_workspaces(user)
  workspace = workspaces.select { |w| w['name'] == 'De Praktijk Index' }.first

  toggl_reports_api = TogglV8::ReportsV2.new(api_token: toggl_api_token)
  toggl_reports_api.workspace_id = workspace['id']
  toggl_records = toggl_reports_api.details(:json,
                                            since: toggl_reports_since,
                                            until: toggl_reports_until,
                                            order_desc: 'off')

  afas_time_entries = toggl_records.map do |toggl_record|
    description = toggl_record['description']
    project = toggl_record['project']
    tags = toggl_record['tags']
    duration = toggl_record['dur']
    start_time = DateTime.parse(toggl_record['start'])

    afas_project = /\((.*)\)/.match(project).to_a[1]
    afas_description = description

    unless afas_project
      afas_description = [project, description].reject { |d| d == '' }.join(': ')
      afas_project = 'ALG'
    end

    afas_time_entry = Afas::InSite::TimeEntry.new(start_time.to_date,
                                          afas_project,
                                          'Wst',
                                          tags.first,
                                          nil,
                                          'N',
                                          afas_description)

    afas_time_entry.duration_from_milliseconds(duration)

    next unless afas_time_entry.duration > 0

    afas_time_entry
  end

  click_bot = Afas::InSite::ClickBot.new(session)
  click_bot.sign_in
  click_bot.fill_in_working_hours(afas_time_entries)
ensure
  session.driver.quit
end
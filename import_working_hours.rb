# frozen_string_literal: true

require "capybara"
require "json"
require "rails"
require "selenium-webdriver"
require "togglv8"

require_relative "lib/afas"

begin
  Capybara.default_max_wait_time = 10

  Capybara.register_driver(:selenium_firefox) do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile["extensions.update.enabled"] = false
    profile["app.update.enabled"] = false
    profile["app.update.auto"] = false
    Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
  end

  Capybara.default_driver = :selenium_firefox

  session = Capybara::Session.new(:selenium_firefox)

  # Read environment
  toggl_api_token = ENV.fetch("TOGGL_API_TOKEN").freeze
  toggl_reports_since = Time.parse(ENV["SINCE"]).to_time if ENV["SINCE"]
  toggl_reports_until = Time.parse(ENV["UNTIL"]).to_time if ENV["UNTIL"]
  year = ENV.fetch("YEAR", Time.new.year).to_i
  week = ENV.fetch("WEEK", -1).to_i
  if week.positive?
    toggl_reports_since ||= Date.commercial(year, week).to_time
    toggl_reports_until ||= Date.commercial(year, week).to_time.end_of_week.end_of_day
  end

  # Toggl
  toggl_api = TogglV8::API.new(toggl_api_token)
  user = toggl_api.me(all = true) # rubocop:disable Lint/UselessAssignment
  workspaces = toggl_api.my_workspaces(user)
  workspace = workspaces.select { |w| w["name"] == "De Praktijk Index" }.first

  toggl_reports_api = TogglV8::ReportsV2.new(api_token: toggl_api_token)
  toggl_reports_api.workspace_id = workspace["id"]
  toggl_records = toggl_reports_api.details(:json,
                                            since: toggl_reports_since,
                                            until: toggl_reports_until,
                                            order_desc: "off")

  afas_time_entries = toggl_records.map do |toggl_record|
    id = toggl_record["id"]
    description = toggl_record["description"]
    project = toggl_record["project"]
    tags = toggl_record["tags"]
    duration = toggl_record["dur"]
    start_time = Time.parse(toggl_record["start"])

    afas_project = /\((.*)\)/.match(project).to_a[1]

    unless afas_project
      description = [project, description].reject { |d| d == "" }.join(": ")
      afas_project = "ALG"
    end

    afas_time_entry = Afas::InSite::TimeEntry.new(id,
                                                  start_time.to_date,
                                                  afas_project,
                                                  tags.first,
                                                  duration,
                                                  description)

    next unless afas_time_entry.afas_duration.positive?

    afas_time_entry
  end

  session.driver.browser.manage.window.maximize
  session.visit(Afas::InSite::URL)
  click_bot = Afas::InSite::ClickBot.new(session)
  click_bot.close_amber_alert
  click_bot.sign_in
  click_bot.open_working_hours_form
  click_bot.fill_in_working_hours(afas_time_entries.compact)
ensure
  session&.driver&.quit
end

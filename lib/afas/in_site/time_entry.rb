# frozen_string_literal: true

module Afas
  module InSite
    # Afas InSite formatted time entries.
    class TimeEntry
      TYPE_OF_WORK = "Wst"
      TYPE_OF_HOURS = "N"

      attr_accessor :id, :date, :project, :type_of_work, :code, :toggl_duration, :type_of_hours, :description

      def initialize(id, date, project, code, toggl_duration, description)
        @id = id
        @date = date
        @project = project
        @type_of_work = TYPE_OF_WORK
        @code = code
        @toggl_duration = toggl_duration
        @type_of_hours = TYPE_OF_HOURS
        @description = description
      end

      def year
        date.year
      end

      def week
        date.cweek
      end

      def afas_date
        date.strftime("%d-%m-%Y")
      end

      def afas_duration
        duration_in_twentieth_of_hours = toggl_duration.fdiv(180_000) * 0.05
        afas_duration = (duration_in_twentieth_of_hours * 20).round.fdiv(20)
        afas_duration -= 0.5 if description == "Lunch"
        afas_duration.round(2)
      end

      def afas_description
        "#{time_entry.description} (TogglID: #{time_entry.id})"
      end
    end
  end
end

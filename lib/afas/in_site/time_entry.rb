module Afas
  module InSite
    class TimeEntry
      attr_accessor :date, :project, :type_of_work, :code, :duration,
                    :type_of_hours, :description

      def initialize(date, project, type_of_work, code, duration, type_of_hours,
                     description)
        @date = date
        @project = project
        @type_of_work = type_of_work
        @code = code
        @duration = duration
        @type_of_hours = type_of_hours
        @description = description
      end

      def year
        date.year
      end

      def week
        date.cweek
      end

      def duration_from_milliseconds(duration_in_milliseconds)
        seconds = duration_in_milliseconds / 1000.0
        minutes = seconds / 60.0
        hours = minutes / 60.0

        complete_hours = hours.floor
        complete_minutes = (minutes - (complete_hours * 60)).floor
        complete_seconds = (seconds - (minutes.floor * 60)).floor

        mins = ((complete_minutes / 3.0) * 5) / 100.0
        secs = ((complete_seconds / 3.0)) * 5 / 10_000.0

        afas_duration = complete_hours + mins + secs

        afas_duration -= 0.5 if description == 'Lunch'

        @duration = (afas_duration * 20).round / 20.0
      end

      class << self
        def from_toggl_time_entry(toggl_time_entry)

        end
      end
    end
  end
end

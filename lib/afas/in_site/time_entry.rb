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

      class << self
        def from_toggl_time_entry(toggl_time_entry)

        end
      end
    end
  end
end

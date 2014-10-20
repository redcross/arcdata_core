begin

require 'active_admin'

module Core
  module Admin
    class LogStatusIndexView < ::ActiveAdmin::Component
      #run_counts = base.select{[controller, name, count(id).as(:count)]}.group{[controller, name]}.group_by{|r| [r.controller, r.name]}

      def base
         Core::JobLog.where{created_at > 1.month.ago}
       end

      def latest_ids
        base.select{[tenant_id, tenant_type, name, max(id).as('id')]}.group{[tenant_type, tenant_id, name]}.to_a
      end

      def latest_logs
        latest_logs = Core::JobLog.where{id.in(my{latest_ids})}.order{[name, tenant_type, tenant_id]}.group_by(&:name)
      end

      def headers
        tr do
          th "Name", colspan: 3
          th "Status", colspan: 3
          th "Most Recent Run", colspan: 2, rowspan: 2
        end
        tr do
          th
          th "ID"
          th "Name"
          th "Result"
          th "# Rows"
          th "Runtime"
        end
      end

      def group_row name, group
        total = group.count
        last_run = group.map(&:created_at).min
        success = group.count{|log| log.result == 'success' }
        state = (total == success) ? 'success' : 'error'

        tbody class: 'controller-group' do
          tr class: 'even' do
            td colspan: 3 do
              name_link name
            end
            td state
            td "#{success}/#{total}"
            td
            td last_run.to_s(:date_time)
            td format_time(last_run)
          end
        end
      end

      def format_duration dur
        dur.present? && ("%0.1fs" % dur)
      end

      def format_time time
        time_ago_in_words(time, include_seconds: false)
      end

      def name_link name
        link_to name, {q: {name_eq: name}, as: 'table'}
      end

      def action_link log
        link_to (log.tenant_id ? "#{log.tenant_type}##{log.tenant_id}" : 'Log'), {q: {name_eq: log.name, tenant_id_eq: log.tenant_id, tenant_type_eq: log.tenant_type}, as: 'table'}
      end

      def status_row log
        tr class: 'odd' do
          td
          td link_to(log.id, resource_path(log))
          td action_link(log)
          td log.result
          td log.num_rows
          td format_duration(log.runtime)
          td log.created_at.to_s(:date_time)
          td format_time(log.created_at)
        end
      end

      def build(page_presenter, collection_unused)
        table class: "index_table" do
          thead do
            headers
          end
          latest_logs.each do |controller, group|
            group_row(controller, group)
            tbody class: 'row-group' do
              group.each do |log|
                status_row(log)
              end
            end
          end
        end
      end

      def self.index_name
        "log_status"
      end

    end
  end
end

rescue LoadError

end

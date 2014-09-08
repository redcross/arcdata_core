class CreateJobLogs < ActiveRecord::Migration
  def change
    create_table :job_logs do |t|
      t.string :name
      t.references :tenant, polymorphic: true
      t.string :result

      t.string :message_subject
      t.string :file_name
      t.integer :file_size

      t.integer :num_rows
      t.text :log
      t.text :import_errors
      t.string :exception
      t.string :exception_message
      t.text :exception_trace

      t.float :runtime

      t.timestamps
    end
  end
end

class InstallSolidTables < ActiveRecord::Migration[8.1]
  def change
    create_solid_cache_tables
    create_solid_queue_tables
  end

  private

  def create_solid_cache_tables
    return if table_exists?(:solid_cache_entries)

    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false
      t.index :byte_size
      t.index %i[key_hash byte_size]
      t.index :key_hash, unique: true
    end
  end

  def create_solid_queue_tables
    create_queue_jobs
    create_queue_batches
    create_queue_executions
    create_queue_support_tables
    add_queue_foreign_keys
  end

  def create_queue_jobs
    unless table_exists?(:solid_queue_jobs)
      create_table :solid_queue_jobs do |t|
        t.string :queue_name, null: false
        t.string :class_name, null: false
        t.text :arguments
        t.integer :priority, default: 0, null: false
        t.string :active_job_id
        t.datetime :scheduled_at
        t.datetime :finished_at
        t.string :concurrency_key
        t.timestamps
        t.bigint :batch_id
        t.index :active_job_id
        t.index :batch_id
        t.index :class_name
        t.index :finished_at
        t.index %i[queue_name finished_at], name: :index_solid_queue_jobs_for_filtering
        t.index %i[scheduled_at finished_at], name: :index_solid_queue_jobs_for_alerting
      end
    end

    unless column_exists?(:solid_queue_jobs, :batch_id)
      add_column :solid_queue_jobs, :batch_id, :bigint
      add_index :solid_queue_jobs, :batch_id
    end
  end

  def create_queue_batches
    unless table_exists?(:solid_queue_batches)
      create_table :solid_queue_batches do |t|
        t.string :active_job_batch_id
        t.string :description
        t.text :on_finish
        t.text :on_success
        t.text :on_failure
        t.text :metadata
        t.integer :total_jobs, default: 0, null: false
        t.integer :completed_jobs, default: 0, null: false
        t.integer :failed_jobs, default: 0, null: false
        t.datetime :enqueued_at
        t.datetime :finished_at
        t.datetime :failed_at
        t.timestamps
        t.index :active_job_batch_id, unique: true
        t.index :finished_at
      end
    end

    return if table_exists?(:solid_queue_batch_executions)

    create_table :solid_queue_batch_executions do |t|
      t.bigint :job_id, null: false
      t.bigint :batch_id, null: false
      t.datetime :created_at, null: false
      t.index :job_id, unique: true
      t.index :batch_id
    end
  end

  def create_queue_executions
    unless table_exists?(:solid_queue_blocked_executions)
      create_table :solid_queue_blocked_executions do |t|
        t.bigint :job_id, null: false
        t.string :queue_name, null: false
        t.integer :priority, default: 0, null: false
        t.string :concurrency_key, null: false
        t.datetime :expires_at, null: false
        t.datetime :created_at, null: false
        t.index %i[concurrency_key priority job_id], name: :index_solid_queue_blocked_executions_for_release
        t.index %i[expires_at concurrency_key], name: :index_solid_queue_blocked_executions_for_maintenance
        t.index :job_id, unique: true
      end
    end

    unless table_exists?(:solid_queue_claimed_executions)
      create_table :solid_queue_claimed_executions do |t|
        t.bigint :job_id, null: false
        t.bigint :process_id
        t.datetime :created_at, null: false
        t.index :job_id, unique: true
        t.index %i[process_id job_id]
      end
    end

    unless table_exists?(:solid_queue_failed_executions)
      create_table :solid_queue_failed_executions do |t|
        t.bigint :job_id, null: false
        t.text :error
        t.datetime :created_at, null: false
        t.index :job_id, unique: true
      end
    end

    unless table_exists?(:solid_queue_ready_executions)
      create_table :solid_queue_ready_executions do |t|
        t.bigint :job_id, null: false
        t.string :queue_name, null: false
        t.integer :priority, default: 0, null: false
        t.datetime :created_at, null: false
        t.index :job_id, unique: true
        t.index %i[priority job_id], name: :index_solid_queue_poll_all
        t.index %i[queue_name priority job_id], name: :index_solid_queue_poll_by_queue
      end
    end

    unless table_exists?(:solid_queue_scheduled_executions)
      create_table :solid_queue_scheduled_executions do |t|
        t.bigint :job_id, null: false
        t.string :queue_name, null: false
        t.integer :priority, default: 0, null: false
        t.datetime :scheduled_at, null: false
        t.datetime :created_at, null: false
        t.index :job_id, unique: true
        t.index %i[scheduled_at priority job_id], name: :index_solid_queue_dispatch_all
      end
    end

    unless table_exists?(:solid_queue_recurring_executions)
      create_table :solid_queue_recurring_executions do |t|
        t.bigint :job_id, null: false
        t.string :task_key, null: false
        t.datetime :run_at, null: false
        t.datetime :created_at, null: false
        t.index :job_id, unique: true
        t.index %i[task_key run_at], unique: true
      end
    end
  end

  def create_queue_support_tables
    unless table_exists?(:solid_queue_recurring_tasks)
      create_table :solid_queue_recurring_tasks do |t|
        t.string :key, null: false
        t.string :schedule, null: false
        t.string :command, limit: 2048
        t.string :class_name
        t.text :arguments
        t.string :queue_name
        t.integer :priority, default: 0
        t.boolean :static, default: true, null: false
        t.text :description
        t.timestamps
        t.index :key, unique: true
        t.index :static
      end
    end

    unless table_exists?(:solid_queue_pauses)
      create_table :solid_queue_pauses do |t|
        t.string :queue_name, null: false
        t.datetime :created_at, null: false
        t.index :queue_name, unique: true
      end
    end

    unless table_exists?(:solid_queue_processes)
      create_table :solid_queue_processes do |t|
        t.string :kind, null: false
        t.datetime :last_heartbeat_at, null: false
        t.bigint :supervisor_id
        t.integer :pid, null: false
        t.string :hostname
        t.text :metadata
        t.datetime :created_at, null: false
        t.string :name, null: false
        t.index :last_heartbeat_at
        t.index %i[name supervisor_id], unique: true
        t.index :supervisor_id
      end
    end

    return if table_exists?(:solid_queue_semaphores)

    create_table :solid_queue_semaphores do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.timestamps
      t.index :expires_at
      t.index %i[key value]
      t.index :key, unique: true
    end
  end

  def add_queue_foreign_keys
    add_queue_foreign_key :solid_queue_batch_executions, :solid_queue_batches, column: :batch_id
    %i[batch_executions blocked_executions claimed_executions failed_executions ready_executions recurring_executions scheduled_executions].each do |table|
      add_queue_foreign_key "solid_queue_#{table}", :solid_queue_jobs, column: :job_id
    end
  end

  def add_queue_foreign_key(from, to, column:)
    return unless table_exists?(from) && table_exists?(to)
    return if foreign_key_exists?(from, to, column: column)

    add_foreign_key from, to, column: column, on_delete: :cascade
  end
end

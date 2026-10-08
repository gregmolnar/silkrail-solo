class UseActionTextForReleasesAndProductUpdates < ActiveRecord::Migration[8.1]
  def up
    migrate_column(:releases, :notes, "Release", "notes")
    migrate_column(:product_updates, :body, "ProductUpdate", "body")

    remove_column :releases, :notes, :text
    remove_column :product_updates, :body, :text
  end

  def down
    add_column :releases, :notes, :text
    add_column :product_updates, :body, :text

    restore_column(:releases, :notes, "Release", "notes")
    restore_column(:product_updates, :body, "ProductUpdate", "body")
  end

  private

  def migrate_column(table, column, record_type, name)
    now = connection.quote(Time.current)

    connection.select_all("SELECT id, #{column} FROM #{table} WHERE #{column} IS NOT NULL AND #{column} <> ''").each do |record|
      body = connection.quote(plain_text_html(record.fetch(column.to_s)))
      record_id = connection.quote(record.fetch("id"))
      execute <<~SQL.squish
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        VALUES (#{connection.quote(name)}, #{body}, #{connection.quote(record_type)}, #{record_id}, #{now}, #{now})
      SQL
    end
  end

  def restore_column(table, column, record_type, name)
    connection.select_all(<<~SQL.squish).each do |rich_text|
      SELECT record_id, body
      FROM action_text_rich_texts
      WHERE record_type = #{connection.quote(record_type)}
        AND name = #{connection.quote(name)}
    SQL
      execute <<~SQL.squish
        UPDATE #{table}
        SET #{column} = #{connection.quote(rich_text.fetch("body"))}
        WHERE id = #{connection.quote(rich_text.fetch("record_id"))}
      SQL
    end

    execute <<~SQL.squish
      DELETE FROM action_text_rich_texts
      WHERE record_type = #{connection.quote(record_type)}
        AND name = #{connection.quote(name)}
    SQL
  end

  def plain_text_html(value)
    value.to_s.split(/\n{2,}/).map do |paragraph|
      "<p>#{ERB::Util.html_escape(paragraph).gsub("\n", "<br>")}</p>"
    end.join
  end
end

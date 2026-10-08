class UseActionTextForProductDescriptions < ActiveRecord::Migration[8.1]
  def up
    create_table :action_text_rich_texts do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false
      t.timestamps
      t.index %i[record_type record_id name], name: :index_action_text_rich_texts_uniqueness, unique: true
    end

    migrate_product_descriptions
    remove_column :products, :description, :text
  end

  def down
    add_column :products, :description, :text

    execute <<~SQL.squish
      UPDATE products
      SET description = action_text_rich_texts.body
      FROM action_text_rich_texts
      WHERE action_text_rich_texts.record_type = 'Product'
        AND action_text_rich_texts.record_id = products.id
        AND action_text_rich_texts.name = 'description'
    SQL

    drop_table :action_text_rich_texts
  end

  private

  def migrate_product_descriptions
    now = connection.quote(Time.current)

    connection.select_all("SELECT id, description FROM products WHERE description IS NOT NULL AND description <> ''").each do |product|
      body = connection.quote(plain_text_html(product.fetch("description")))
      product_id = connection.quote(product.fetch("id"))
      execute <<~SQL.squish
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        VALUES ('description', #{body}, 'Product', #{product_id}, #{now}, #{now})
      SQL
    end
  end

  def plain_text_html(value)
    value.to_s.split(/\n{2,}/).map do |paragraph|
      "<p>#{ERB::Util.html_escape(paragraph).gsub("\n", "<br>")}</p>"
    end.join
  end
end

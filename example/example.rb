require_relative "../lib/khala"

class ShoppingList
  attr_reader :name
  attr_reader :items

  def initialize(name:)
    @name = name
    @items = []
  end

  def <<(item)
    @items << ShoppingItem.new(item)
  end
end

class ShoppingItem
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

shopping_list = ShoppingList.new(name: "My Shopping List")
shopping_list << "Tomatoes"
shopping_list << "Cucumbers"
shopping_list << "Apples"

template = Khala::Template.load("shopping", templates: "example")
result = template.execute(shopping_list)

File.write("example/result.html", result)

require_relative "spec_helper"
require_relative "../lib/khala"

describe "khala" do
  class ViewModel < Struct.new(:name, :items)
    def yes
      true
    end

    def no
      false
    end
  end

  let(:view_model) { ViewModel.new("World", %w[fizz buzz]) }

  it "should pass an HTML string through" do
    template = Khala::Template.new('<h1 class="foo">Hello<br><strong>World</strong></h1>')
    result = template.execute(view_model)
    expect(result).to eq_html '<h1 class="foo">Hello<br><strong>World</strong></h1>'
  end

  it "should complain about mismatched tags" do
    expect {
      Khala::Template.new('<h1 class="foo">Hello <strong>World</h1>')
    }.to raise_error(/Opening and ending tag mismatch/)
  end

  it "should complain about non-existing tags" do
    expect {
      Khala::Template.new('<idontexist></idontexist>')
    }.to raise_error(/Tag idontexist invalid/)
  end

  it "should insert a variable with data-replace" do
    template = Khala::Template.new('<h1 class="foo" data-replace="name">Hello <strong>World</strong></h1>')
    result = template.execute(view_model)
    expect(result).to eq_html '<h1 class="foo">World</h1>'
  end

  it "should insert a variable with data-replace in a nested document" do
    template = Khala::Template.new('<h1 class="foo">Hello <span data-replace="name">World</span></h1>')
    result = template.execute(view_model)
    expect(result).to eq_html '<h1 class="foo">Hello <span>World</span></h1>'
  end

  it "should iterate over a collection with data-each" do
    template = Khala::Template.new('<ul><li class="foo" data-each="item: items">Example</li></ul>')
    result = template.execute(view_model)
    expect(result).to eq_html '<ul><li class="foo">Example</li><li class="foo">Example</li></ul>'
  end

  it "should iterate over a collection with data-each and data-replace" do
    template = Khala::Template.new('<ul><li class="foo" data-each="item: items" data-replace="item">Example</li></ul>')
    result = template.execute(view_model)
    expect(result).to eq_html '<ul><li class="foo">fizz</li><li class="foo">buzz</li></ul>'
  end

  it "should iterate over a collection with data-each and an inner element with data-replace" do
    template = Khala::Template.new('<ul><li class="foo" data-each="item: items">Hello <strong data-replace="item">Example</strong></li></ul>')
    result = template.execute(view_model)
    expect(result).to eq_html '<ul><li class="foo">Hello <strong>fizz</strong></li><li class="foo">Hello <strong>buzz</strong></li></ul>'
  end

  it "should hide the content with data-ignore" do
    template = Khala::Template.new('<h1 class="foo" data-ignore>Hello <strong>World</strong></h1><strong>Hey</strong>')
    result = template.execute(view_model)
    expect(result).to eq_html '<strong>Hey</strong>'
  end

  it "should show the content if data-if evaluates to true" do
    template = Khala::Template.new('<h1 class="foo" data-if="yes">Hello <strong>World</strong></h1>')
    result = template.execute(view_model)
    expect(result).to eq_html '<h1 class="foo">Hello <strong>World</strong></h1>'
  end

  it "should hide the content if data-if evaluates to false" do
    template = Khala::Template.new('<h1 class="foo" data-if="no">Hello <strong>World</strong></h1><strong>Hey</strong>')
    result = template.execute(view_model)
    expect(result).to eq_html '<strong>Hey</strong>'
  end

  context "with a template 'strong' available to load" do
    class FakeLoader
      def initialize(templates)
        @templates = templates
      end

      def load(template_name)
        @templates[template_name]
      end
    end

    let(:fake_loader) { FakeLoader.new(templates) }
    let(:templates) do
      {
        "strong" => '<strong class="very-strong" data-replace="label">Foo</strong>'
      }
    end

    it "should expand the components c-strong" do
      template = Khala::Template.new('<h1>Hello <c-strong label="name">Example</c-strong></h1><p>Hi</p>', loader: fake_loader)
      result = template.execute(view_model)
      expect(result).to eq_html '<h1>Hello <strong class="very-strong">World</strong></h1><p>Hi</p>'
    end
  end
end

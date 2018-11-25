# khala

A template engine. The goal is to be **portable**: khala should be easily
ported to any language, the templates are supposed to work in each
implementation and should be writeable by anyone who knows HTML. To achieve
this, we define the following characteristics:

* Parseable, valid HTML:
  * To parse khala, you should be able to use an HTML parser that is available
      in your language of choice.
  * This also means that you can open a khala template in a browser. It can
      contain example data so it makes sense.
* It is logic-less so the templates can be used with different host languages.
* Components are first class citizens.
* A template with all its modules should always be converted to a single function
  in the host language.

## How it works

Every valid HTML document is a valid khala template. You can add attributes to
your nodes to make the template dynamic.

```html
<h1 data-replace="title">My Example Title</h1>
```

This will replace the content of the tag with the value of `title`. What is the
value of title? This depends on the object you provide. Here is an example:

```ruby
class ViewModel
  def title
    "My Title"
  end
end

template = Khala::Template.new('<h1 data-replace="title">My Example Title</h1>')

template.execute(ViewModel.new) # "<html><body><h1>My Title</h1></body></html>"
```

This is how it works in Ruby. Depending on the language, this can also work
without Objects – the template could for example be converted into a function
that takes a data structure and returns a String.

We can also iterate over collections with `data-each`. It takes the form
`item: collection`, where `collection` is the name of the list you want to
iterate, and `item` is the variable name it takes during the iteration:

```html
<ul class="shopping-list">
  <li class="shopping-item" data-each="item: items" data-replace="item">
    Example Item
  </li>
</ul>
```

The replacement can also happen in a nested tag:

```html
<ul class="shopping-list">
  <li class="shopping-item" data-each="item: items">
    Item: <strong data-replace="item">Example Data</strong>
  </li>
</ul>
```

You can also ignore certain tags if you only need them for example data:

```html
<ul class="shopping-list">
  <li class="shopping-item" data-each="item: items" data-replace="item">
    Example Item 1
  </li>
  <li class="shopping-item" data-ignore>
    Example Item 2
  </li>
</ul>
```

You can only show a tag if a certain condition is fulfilled:

```html
<h1>Hello World</h1>

<a href="/admin" data-if="is_admin">Admin Area</a>
```

We want to be able to reuse components. In order to do that, we store the template
for a component in a file and then reference it. Let's put the following content
in a file called `strong.html`:

```html
<strong class="really-strong" data-replace="label">Example Item</strong>
```

Now we can reference it like this from another template:

```html
<h1 data-replace="name">Example Shopping List</h1>

<ul class="shopping-list">
  <li class="shopping-item" data-each="item: items">
    <c-strong label="item.name">Example Item</c-strong>
  </li>
</ul>
```

Tags that start with `c-` (in this example: `c-strong`) will be replaced by
rendering the template. The attributes allow you to pass data from the
current context to the rendered template (in this case, there will be
a variable `label` assigned to the value of `item.name`).

Currently, the "inner HTML" of these items will be removed. But I'm thinking
about passing it to the rendered template (for example as `yield`). Among other
things, this will enable a use-case like a `c-layout` to render something in
a shared layout.

## Workflow

I imagine the workflow to work something like this:

* A frontend developer works in a pattern library. They write khala templates and
  no presentation logic.
* Within the pattern library, components can be reused without copying.
* In the pattern library, the provided example data is shown.
* All applications that use this pattern library can use these templates,
  they just need to provide the presentation logic in the form of simple ViewModels
  or data structures.

## Inspiration

khala is inspired by Mustache, Thymeleaf and JSX. The implementation is
inspired by Erubi. It is also inspired by conversations with my amazing
colleagues at @INNOQ, especially:

* @nerdbabe
* @joyheron
* @fnd
* @martinei

## License

khala is licensed under the Apache 2.0 License.

## 3.0.0

* [BREAKING] Require Pundit 2.0
* [BREAKING] Rename `resource` to `model` and `resources` to `collection`
* [BREAKING] Rewrite `model_class` as class attribute
* [BREAKING] Rename locales file to flash.en.yml
* [BREAKING] Scope flash message i18n keys
* [BREAKING] Change flash message interpolation arguments
* [BREAKING] Rewrite `Controller#vest` as `Controller#assign_attributes`
* Allow any Rails >= 5.1
* Raise helpful error when invalid action specified to `garden_variety`
  macro
* Integrate with talent_scout gem (optional)


## 2.0.0

* [BREAKING] Support flash messages
* [BREAKING] Handle `destroy` failures by rendering `show` template
* Support SJR (Server-generated JavaScript Response) integration


## 1.2.0

* Accept model params in `new` action, enabling pre-population of forms
  via URL query params
* Support namespaced controllers


## 1.1.2

* Actually loosen Rails version constraint


## 1.1.1

* ~~Loosen Rails version constraint~~


## 1.1.0

* Support concise syntax for overriding the on-success redirect of the
  `create`, `update`, and `destroy` actions


## 1.0.0

* Initial release
